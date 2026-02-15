#!/usr/bin/env python3
import json
import logging
import os
import signal
import subprocess
import sys
import time

from azure.servicebus import ServiceBusClient


NGROK_SERVICE = "mapineda48-ngrok.service"


class Shutdown:
    def __init__(self) -> None:
        self._stop = False

    def request(self, *_args) -> None:
        self._stop = True

    @property
    def requested(self) -> bool:
        return self._stop


def systemctl(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["/usr/bin/systemctl", *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )


def ngrok_is_active() -> bool:
    cp = systemctl(["is-active", "--quiet", NGROK_SERVICE])
    return cp.returncode == 0


def ngrok_start() -> None:
    cp = systemctl(["start", NGROK_SERVICE])
    if cp.returncode != 0:
        raise RuntimeError(f"failed to start ngrok: {cp.stdout.strip()}")


def ngrok_stop() -> None:
    cp = systemctl(["stop", NGROK_SERVICE])
    if cp.returncode != 0:
        raise RuntimeError(f"failed to stop ngrok: {cp.stdout.strip()}")


def ngrok_toggle() -> str:
    if ngrok_is_active():
        ngrok_stop()
        return "stopped"
    ngrok_start()
    return "started"


def _message_to_text(msg) -> str:
    # azure-servicebus message bodies can be a generator of bytes.
    try:
        body = msg.body
        if isinstance(body, (bytes, bytearray)):
            return body.decode("utf-8", errors="replace")
        chunks = []
        for part in body:
            if isinstance(part, (bytes, bytearray)):
                chunks.append(part.decode("utf-8", errors="replace"))
            else:
                chunks.append(str(part))
        return "".join(chunks)
    except Exception:
        return str(msg)


def _extract_event(text: str) -> str:
    s = text.strip()
    if not s:
        return ""

    # Accept either raw string event or JSON payload.
    if s.startswith("{"):
        try:
            data = json.loads(s)
            event = data.get("event") or data.get("type") or data.get("command")
            if isinstance(event, str):
                return event.strip()
        except json.JSONDecodeError:
            pass

    return s


def process_event(event: str) -> str:
    if event == "pgadmin-toggle-ngrok":
        return f"ngrok:{ngrok_toggle()}"

    if event == "pgadmin-ngrok-start":
        if not ngrok_is_active():
            ngrok_start()
            return "ngrok:started"
        return "ngrok:already-active"

    if event == "pgadmin-ngrok-stop":
        if ngrok_is_active():
            ngrok_stop()
            return "ngrok:stopped"
        return "ngrok:already-stopped"

    return "ignored"


def main() -> int:
    shutdown = Shutdown()
    signal.signal(signal.SIGTERM, shutdown.request)
    signal.signal(signal.SIGINT, shutdown.request)

    conn_str = os.getenv("SERVICE_BUS_CONNECTION_STRING")
    queue_name = os.getenv("SERVICE_BUS_QUEUE_NAME", "")
    log_level = os.getenv("SERVICE_BUS_LOG_LEVEL", "INFO").upper()

    logging.basicConfig(
        level=getattr(logging, log_level, logging.INFO),
        format="%(asctime)s %(levelname)s %(message)s",
    )

    if not conn_str:
        logging.error("SERVICE_BUS_CONNECTION_STRING not set; waiting")
        while not shutdown.requested:
            time.sleep(30)
        return 0
    if not queue_name:
        logging.error("SERVICE_BUS_QUEUE_NAME not set; waiting")
        while not shutdown.requested:
            time.sleep(30)
        return 0

    backoff = 2
    logging.info("servicebus listener started; queue=%s", queue_name)

    while not shutdown.requested:
        try:
            with ServiceBusClient.from_connection_string(conn_str) as client:
                with client.get_queue_receiver(queue_name=queue_name, max_wait_time=30) as receiver:
                    backoff = 2
                    while not shutdown.requested:
                        messages = receiver.receive_messages(max_message_count=1, max_wait_time=30)
                        if not messages:
                            continue

                        for msg in messages:
                            text = _message_to_text(msg)
                            event = _extract_event(text)
                            if not event:
                                logging.warning("empty message received")
                                receiver.complete_message(msg)
                                continue

                            logging.info("received event=%s", event)
                            try:
                                result = process_event(event)
                                logging.info("processed event=%s result=%s", event, result)
                                receiver.complete_message(msg)
                            except Exception as e:
                                # Abandon so it can be retried if transient.
                                logging.exception("failed processing event=%s: %s", event, e)
                                receiver.abandon_message(msg)

        except Exception as e:
            logging.exception("listener loop error: %s", e)
            time.sleep(backoff)
            backoff = min(backoff * 2, 60)

    logging.info("servicebus listener stopping")
    return 0


if __name__ == "__main__":
    sys.exit(main())
