"""Phase 3 — convert Markdown → PDF.

Pure-Python pipeline (không yêu cầu GTK / wkhtmltopdf):
1. `markdown` package → HTML.
2. `xhtml2pdf` → PDF bytes.

Hạn chế: xhtml2pdf không support 100% CSS3, nhưng đủ cho table/heading/list
mà ReportTool sinh ra. Phase 4+ có thể chuyển sang WeasyPrint nếu chạy Linux.
"""
from __future__ import annotations

import io

import markdown as md_lib
from xhtml2pdf import pisa

from .logging_service import get_logger

_logger = get_logger(__name__)


_BASE_CSS = """
@page { size: A4; margin: 1.8cm 1.6cm 1.8cm 1.6cm; }
body { font-family: 'Times New Roman', serif; font-size: 11pt; color: #111; line-height: 1.45; }
h1 { color: #1B3A6B; font-size: 18pt; border-bottom: 2px solid #1B3A6B; padding-bottom: 4pt; }
h2 { color: #1B3A6B; font-size: 14pt; margin-top: 14pt; }
h3 { color: #1F3C93; font-size: 12pt; }
table { border-collapse: collapse; width: 100%; margin: 6pt 0; }
th { background: #EBF2FB; color: #1B3A6B; text-align: left; padding: 4pt; border: 1px solid #C9D7EA; }
td { padding: 4pt; border: 1px solid #C9D7EA; }
ul, ol { padding-left: 18pt; }
blockquote { border-left: 3pt solid #1B3A6B; padding: 2pt 8pt; color: #444; background: #F4F8FE; }
code { font-family: 'Courier New', monospace; background: #F0F0F0; padding: 1pt 3pt; }
"""


class PdfRenderError(Exception):
    """xhtml2pdf trả error pages — bubble lên controller."""


def render_markdown_to_pdf(markdown_text: str, *, title: str | None = None) -> bytes:
    """Trả bytes PDF. Khi lỗi: raise `PdfRenderError`."""
    html_body = md_lib.markdown(
        markdown_text,
        extensions=["tables", "fenced_code", "sane_lists"],
        output_format="xhtml",
    )

    page_title = title or "Báo cáo Loca AI"
    full_html = (
        f"<!DOCTYPE html>\n<html><head>"
        f"<meta charset=\"utf-8\"/>"
        f"<title>{page_title}</title>"
        f"<style>{_BASE_CSS}</style>"
        f"</head><body>{html_body}</body></html>"
    )

    output = io.BytesIO()
    result = pisa.CreatePDF(src=full_html, dest=output, encoding="utf-8")
    if result.err:
        _logger.warning("pdf.render_failed", err_count=result.err)
        raise PdfRenderError(f"xhtml2pdf trả {result.err} lỗi khi render PDF.")
    output.seek(0)
    return output.getvalue()
