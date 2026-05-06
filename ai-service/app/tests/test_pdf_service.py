"""Test PDF service — xhtml2pdf renders Markdown to bytes."""
from __future__ import annotations

import pytest

from app.services.pdf_service import PdfRenderError, render_markdown_to_pdf


def test_render_simple_markdown_returns_pdf_bytes():
    md = """
# Báo cáo nhanh — Tồn kho

## 1. Tóm tắt điều hành
Tồn kho xăng dầu ổn định.

## 2. Bảng số liệu
| Loại | Tồn |
|---|---|
| RON95 | 125000 |
| DO | 30000 |

## 3. Kiến nghị
- Nhập thêm DO.
- Theo dõi RON92.
"""
    pdf = render_markdown_to_pdf(md, title="Test report")

    assert isinstance(pdf, bytes)
    assert pdf.startswith(b"%PDF-"), "PDF magic bytes phải có ở đầu file"
    assert len(pdf) > 1000  # PDF tối thiểu phải > 1KB cho nội dung này.


def test_render_empty_markdown_still_returns_valid_pdf():
    """xhtml2pdf phải trả PDF rỗng hợp lệ thay vì raise."""
    pdf = render_markdown_to_pdf("", title="Empty")
    assert pdf.startswith(b"%PDF-")


def test_render_with_unicode_vietnamese():
    md = "# Báo cáo\n\nTồn kho **xăng dầu** hôm nay ổn định ở mức 215.000 m³."
    pdf = render_markdown_to_pdf(md)
    assert pdf.startswith(b"%PDF-")
