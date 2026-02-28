from pydantic import BaseModel, Field


class RouteChallenge(BaseModel):
    chlgID: str
    title: str
    type: str
    location: list[str] = Field(min_length=2, max_length=2)
    expected_duration: str
    reason: str = "Recommended for you"


class Route(BaseModel):
    challenges: list[RouteChallenge] = Field(min_length=1)
    total_duration: str
    estimated_travel_time: str = "00:00:00"
    start_location: list[str] = Field(min_length=2, max_length=2)
    end_location: list[str] = Field(min_length=2, max_length=2)


class WorkflowResult(BaseModel):
    response: str
    route: Route | None = None
