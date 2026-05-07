"""Phase 3 — convert Markdown → PDF.

Pure-Python pipeline (không yêu cầu GTK / wkhtmltopdf):
1. `markdown` package → HTML.
2. `xhtml2pdf` → PDF bytes.

Phase 4+: register Unicode TTF từ system fonts để hiển thị tiếng Việt đúng.
xhtml2pdf default chỉ có PDF Type 1 (Helvetica/Times) — không có glyph
tiếng Việt → render `ồ`, `ố`, `ầ`... thành ô vuông.

Font lookup theo OS — không bundle binary trong repo. Production deploy
qua Docker phải đảm bảo image có ít nhất 1 font Unicode (Linux base
phổ biến đã có DejaVu).
"""
from __future__ import annotations

import io
import platform
from pathlib import Path

import markdown as md_lib
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFError, TTFont
from xhtml2pdf import pisa

from .logging_service import get_logger

_logger = get_logger(__name__)

#: Font discovery — thứ tự ưu tiên theo độ phổ biến + chất lượng glyph VN.
_REGULAR_CANDIDATES: tuple[tuple[str, str], ...] = (
    # Windows
    ("LocaUnicode", "C:/Windows/Fonts/arial.ttf"),
    ("LocaUnicode", "C:/Windows/Fonts/calibri.ttf"),
    ("LocaUnicode", "C:/Windows/Fonts/segoeui.ttf"),
    # Linux (Debian/Ubuntu/Alpine với fonts-dejavu)
    ("LocaUnicode", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    ("LocaUnicode", "/usr/share/fonts/dejavu/DejaVuSans.ttf"),
    ("LocaUnicode", "/usr/share/fonts/TTF/DejaVuSans.ttf"),
    # macOS
    ("LocaUnicode", "/Library/Fonts/Arial.ttf"),
    ("LocaUnicode", "/System/Library/Fonts/Supplemental/Arial.ttf"),
)

_BOLD_CANDIDATES: tuple[tuple[str, str], ...] = (
    ("LocaUnicode-Bold", "C:/Windows/Fonts/arialbd.ttf"),
    ("LocaUnicode-Bold", "C:/Windows/Fonts/calibrib.ttf"),
    ("LocaUnicode-Bold", "C:/Windows/Fonts/seguibd.ttf"),
    ("LocaUnicode-Bold", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
    ("LocaUnicode-Bold", "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"),
    ("LocaUnicode-Bold", "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"),
    ("LocaUnicode-Bold", "/Library/Fonts/Arial Bold.ttf"),
    ("LocaUnicode-Bold", "/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
)


_REGISTERED = False
_FONT_NAME_REGULAR = "Helvetica"  # fallback default — sẽ override khi register OK.
_FONT_NAME_BOLD = "Helvetica-Bold"


def _try_register(name: str, path: str) -> bool:
    """Register 1 font với reportlab. Trả True nếu OK."""
    if not Path(path).exists():
        return False
    try:
        pdfmetrics.registerFont(TTFont(name, path))
        return True
    except (TTFError, OSError) as ex:
        _logger.warning("pdf.font_register_failed", name=name, path=path, error=str(ex))
        return False


def _ensure_fonts_registered() -> tuple[str, str]:
    """Idempotent — register Unicode font 1 lần, trả `(regular_name, bold_name)`.
    Nếu không tìm thấy font Unicode → fallback Helvetica (ASCII-only, tiếng Việt sai)."""
    global _REGISTERED, _FONT_NAME_REGULAR, _FONT_NAME_BOLD
    if _REGISTERED:
        return _FONT_NAME_REGULAR, _FONT_NAME_BOLD

    regular_ok = False
    for name, path in _REGULAR_CANDIDATES:
        if _try_register(name, path):
            _FONT_NAME_REGULAR = name
            regular_ok = True
            _logger.info("pdf.font_loaded", role="regular", name=name, path=path)
            break

    if not regular_ok:
        _logger.warning(
            "pdf.no_unicode_font",
            os=platform.system(),
            message="Không tìm thấy Unicode font — PDF tiếng Việt sẽ bị lỗi font. "
                    "Cài `fonts-dejavu` (Linux) hoặc đảm bảo Windows/macOS có Arial.",
        )

    bold_ok = False
    for name, path in _BOLD_CANDIDATES:
        if _try_register(name, path):
            _FONT_NAME_BOLD = name
            bold_ok = True
            break
    if not bold_ok:
        # Fallback: bold cùng font với regular — không bold thật, nhưng tiếng Việt vẫn đúng.
        _FONT_NAME_BOLD = _FONT_NAME_REGULAR

    _REGISTERED = True
    return _FONT_NAME_REGULAR, _FONT_NAME_BOLD


def _build_css(regular: str, bold: str) -> str:
    """Tạo CSS với font đã register. xhtml2pdf đọc font-family theo tên đăng ký."""
    return f"""
@page {{ size: A4; margin: 1.8cm 1.6cm 1.8cm 1.6cm; }}
body {{ font-family: '{regular}', sans-serif; font-size: 11pt; color: #111; line-height: 1.45; }}
h1 {{ font-family: '{bold}', sans-serif; color: #1B3A6B; font-size: 18pt; border-bottom: 2px solid #1B3A6B; padding-bottom: 4pt; }}
h2 {{ font-family: '{bold}', sans-serif; color: #1B3A6B; font-size: 14pt; margin-top: 14pt; }}
h3 {{ font-family: '{bold}', sans-serif; color: #1F3C93; font-size: 12pt; }}
strong, b {{ font-family: '{bold}', sans-serif; }}
table {{ border-collapse: collapse; width: 100%; margin: 6pt 0; }}
th {{ font-family: '{bold}', sans-serif; background: #EBF2FB; color: #1B3A6B; text-align: left; padding: 4pt; border: 1px solid #C9D7EA; }}
td {{ padding: 4pt; border: 1px solid #C9D7EA; }}
ul, ol {{ padding-left: 18pt; }}
blockquote {{ border-left: 3pt solid #1B3A6B; padding: 2pt 8pt; color: #444; background: #F4F8FE; }}
code {{ font-family: 'Courier', monospace; background: #F0F0F0; padding: 1pt 3pt; }}
"""


class PdfRenderError(Exception):
    """xhtml2pdf trả error pages — bubble lên controller."""


def render_markdown_to_pdf(markdown_text: str, *, title: str | None = None) -> bytes:
    """Trả bytes PDF. Khi lỗi: raise `PdfRenderError`.

    Phase 4 fix tiếng Việt: register Unicode font lần đầu được gọi
    (idempotent qua `_REGISTERED` flag).
    """
    regular, bold = _ensure_fonts_registered()

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
        f"<style>{_build_css(regular, bold)}</style>"
        f"</head><body>{html_body}</body></html>"
    )

    output = io.BytesIO()
    result = pisa.CreatePDF(src=full_html, dest=output, encoding="utf-8")
    if result.err:
        _logger.warning("pdf.render_failed", err_count=result.err)
        raise PdfRenderError(f"xhtml2pdf trả {result.err} lỗi khi render PDF.")
    output.seek(0)
    return output.getvalue()
