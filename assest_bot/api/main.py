"""FastAPI app for local development."""
import json
import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.orchestrator.handler import handler


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="Cloud Resource AI Query", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/query")
def query(payload: dict):
    """Post JSON body with 'question' key. Returns orchestrator response."""
    event = {"body": json.dumps(payload) if isinstance(payload, dict) else "{}"}
    resp = handler(event, None)
    body = json.loads(resp["body"]) if isinstance(resp.get("body"), str) else resp.get("body", {})
    return body
