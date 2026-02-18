"""Shared data models."""
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional


class QueryDecision(str, Enum):
    EXECUTABLE = "executable"
    CLARIFY = "clarify"
    UNSUPPORTED = "unsupported"


@dataclass
class FilterSpec:
    field: str
    op: str  # =, !=, in, like, etc.
    value: Any


@dataclass
class QuerySpec:
    resource: str
    filters: List[FilterSpec] = field(default_factory=list)
    select: List[str] = field(default_factory=list)
    group_by: Optional[List[str]] = None
    order_by: Optional[List[str]] = None
    limit: int = 100
    output_format: str = "table"  # table | pie | bar | pivot


@dataclass
class ClarificationRequest:
    message: str
    suggestions: List[str] = field(default_factory=list)


@dataclass
class OrchestratorResponse:
    decision: QueryDecision
    query_spec: Optional[QuerySpec] = None
    clarification: Optional[ClarificationRequest] = None
    raw_llm_output: Optional[str] = None


@dataclass
class ExecutorResult:
    columns: List[str]
    rows: List[List[Any]]
    error: Optional[str] = None


@dataclass
class FormattedResponse:
    format: str  # table | pie | bar
    title: str
    data: Dict[str, Any]
    raw_rows: Optional[List[Dict[str, Any]]] = None
