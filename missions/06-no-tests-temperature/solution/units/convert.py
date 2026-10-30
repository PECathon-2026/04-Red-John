"""Temperature conversions for the weather widget."""
from __future__ import annotations


def celsius_to_fahrenheit(celsius: float) -> float:
    return celsius * 9 / 5 + 32


def fahrenheit_to_celsius(fahrenheit: float) -> float:
    return (fahrenheit - 32) * 5 / 9


def kelvin_to_celsius(kelvin: float) -> float:
    if kelvin < 0:
        raise ValueError("kelvin cannot be negative")
    return kelvin - 273.15
