"""FastAPI dependencies. Routes take what they need from the container here."""
from __future__ import annotations

from typing import Annotated

from fastapi import Depends, Request, WebSocket

from app.container import Container


def get_container(request: Request) -> Container:
    container = getattr(request.app.state, "container", None)
    if container is None:
        container = Container.build()
        request.app.state.container = container
    return container


def get_ws_container(websocket: WebSocket) -> Container:
    container = getattr(websocket.app.state, "container", None)
    if container is None:
        container = Container.build()
        websocket.app.state.container = container
    return container


ContainerDep = Annotated[Container, Depends(get_container)]
WsContainerDep = Annotated[Container, Depends(get_ws_container)]
