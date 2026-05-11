"""Pydantic schemas cho input/output tool — Section 11."""
from __future__ import annotations

from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


# ---------- sp_Ai_GetFuelInventorySummary ----------

class FuelInventoryParams(BaseModel):
    region_id: int | None = None
    province_id: int | None = None
    from_date: date | None = None
    to_date: date | None = None
    fuel_type: str | None = None


class FuelInventoryRow(BaseModel):
    fuel_type: str
    total_stock: Decimal
    stock_unit: str
    previous_period_stock: Decimal | None = None
    change_percent: Decimal | None = None
    min_safe_stock: Decimal | None = None
    is_low_stock: bool
    region_id: int | None = None
    region_name: str | None = None
    as_of_date: date


class FuelInventoryOutput(BaseModel):
    rows: list[FuelInventoryRow]


# ---------- sp_Ai_GetFuelPriceTrend ----------

class FuelPriceTrendParams(BaseModel):
    fuel_type: str = "RON95"
    period_count: int = 3


class FuelPriceTrendRow(BaseModel):
    fuel_type: str
    period_index: int
    period_label: str
    effective_date: date
    price: Decimal
    price_unit: str = "VND/lit"
    change_from_prev: Decimal | None = None


class FuelPriceTrendOutput(BaseModel):
    rows: list[FuelPriceTrendRow]


# ---------- sp_Ai_GetInventoryByHeadOffice ----------

class InventoryByHeadOfficeParams(BaseModel):
    region_id: int | None = None
    province_id: int | None = None
    fuel_type: str = "RON95"
    top: int = 20


class HeadOfficeRow(BaseModel):
    head_office_id: int
    head_office_code: str
    head_office_name: str
    fuel_type: str
    total_stock: Decimal
    stock_unit: str
    min_safe_stock: Decimal | None = None
    is_low_stock: bool
    rank_number: int


class InventoryByHeadOfficeOutput(BaseModel):
    rows: list[HeadOfficeRow]


# ---------- sp_Ai_GetStationDensityByProvince ----------

class StationDensityParams(BaseModel):
    region_id: int | None = None
    province_id: int | None = None


class StationDensityRow(BaseModel):
    province_id: int
    province_code: str
    province_name: str
    region_id: int | None = None
    region_name: str | None = None
    station_count: int
    area_km2: Decimal
    density_per_100km2: Decimal
    density_category: str  # high | medium | low


class StationDensityOutput(BaseModel):
    rows: list[StationDensityRow]


# ---------- Generic tool result ----------

class ToolResult(BaseModel):
    """Wrapper chuẩn cho mọi tool — node `data_analyzer` đọc trường này."""

    model_config = ConfigDict(extra="ignore")

    tool_name: str
    success: bool = True
    rows: list[dict] = Field(default_factory=list)
    summary: dict | None = None
    notes: str | None = None
    error: str | None = None
