"""Markdown → PDF — Phase 4 fix tiếng Việt.

Lý do KHÔNG dùng xhtml2pdf nữa: nó có bug với Unicode tiếng Việt — khi parse
markdown → HTML → PDF, Vietnamese chars (`ồ`, `ề`, `ầ`, ...) bị missing
glyph dù font đã có Unicode coverage. Chứng minh: reportlab Canvas trực tiếp
render đúng với cùng TTF.

Phase 4 chuyển sang reportlab Platypus (high-level layout engine của reportlab):
- Parse markdown bằng `markdown` package → HTML.
- Mapping HTML elements (h1/h2/p/table/ul/blockquote) → Platypus flowables
  (Paragraph/Table/ListFlowable/...).
- Font Unicode đăng ký qua `pdfmetrics.registerFont` — Platypus respect.

Font discovery đa nền tảng:
- Windows: arial.ttf / calibri.ttf
- Linux: DejaVuSans.ttf
- macOS: Arial.ttf

Tradeoff: layout đơn giản hơn xhtml2pdf (không support full CSS), đủ cho
báo cáo Markdown 5 phần (heading + paragraph + table + list + blockquote).
"""
from __future__ import annotations

import io
import platform
from html.parser import HTMLParser
from pathlib import Path

import markdown as md_lib
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFError, TTFont
from reportlab.platypus import (
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from .logging_service import get_logger

_logger = get_logger(__name__)


_REGULAR_CANDIDATES: tuple[str, ...] = (
    # Windows
    "C:/Windows/Fonts/arial.ttf",
    "C:/Windows/Fonts/calibri.ttf",
    "C:/Windows/Fonts/segoeui.ttf",
    "C:/Windows/Fonts/tahoma.ttf",
    # Linux
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/TTF/DejaVuSans.ttf",
    # macOS
    "/Library/Fonts/Arial.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
)

_BOLD_CANDIDATES: tuple[str, ...] = (
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/calibrib.ttf",
    "C:/Windows/Fonts/seguibd.ttf",
    "C:/Windows/Fonts/tahomabd.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf",
    "/Library/Fonts/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
)

_FONT_REGULAR = "Helvetica"
_FONT_BOLD = "Helvetica-Bold"
_FONTS_REGISTERED = False


class PdfRenderError(Exception):
    pass


def _register_fonts() -> None:
    """Idempotent — đăng ký Unicode TTF với reportlab. Fallback Helvetica nếu fail."""
    global _FONTS_REGISTERED, _FONT_REGULAR, _FONT_BOLD
    if _FONTS_REGISTERED:
        return

    for path in _REGULAR_CANDIDATES:
        if not Path(path).exists():
            continue
        try:
            pdfmetrics.registerFont(TTFont("LocaUnicode", path))
            _FONT_REGULAR = "LocaUnicode"
            _logger.info("pdf.font_loaded", role="regular", path=path)
            break
        except (TTFError, OSError) as ex:
            _logger.warning("pdf.font_register_failed", path=path, error=str(ex))

    for path in _BOLD_CANDIDATES:
        if not Path(path).exists():
            continue
        try:
            pdfmetrics.registerFont(TTFont("LocaUnicode-Bold", path))
            _FONT_BOLD = "LocaUnicode-Bold"
            break
        except (TTFError, OSError):
            pass

    if _FONT_REGULAR == "Helvetica":
        _logger.warning(
            "pdf.no_unicode_font",
            os=platform.system(),
            message="Không tìm thấy Unicode TTF — PDF tiếng Việt sẽ bị lỗi font.",
        )

    _FONTS_REGISTERED = True


def _build_styles() -> dict[str, ParagraphStyle]:
    """Tạo style set Platypus dùng font đã register."""
    base = getSampleStyleSheet()["Normal"]
    return {
        "h1": ParagraphStyle(
            "H1", parent=base, fontName=_FONT_BOLD, fontSize=18, leading=22,
            textColor=colors.HexColor("#1B3A6B"), spaceBefore=4, spaceAfter=10,
            borderColor=colors.HexColor("#1B3A6B"), borderPadding=4,
            borderWidth=0,  # underline mô phỏng qua spaceAfter.
        ),
        "h2": ParagraphStyle(
            "H2", parent=base, fontName=_FONT_BOLD, fontSize=14, leading=18,
            textColor=colors.HexColor("#1B3A6B"), spaceBefore=12, spaceAfter=6,
        ),
        "h3": ParagraphStyle(
            "H3", parent=base, fontName=_FONT_BOLD, fontSize=12, leading=15,
            textColor=colors.HexColor("#1F3C93"), spaceBefore=8, spaceAfter=4,
        ),
        "p": ParagraphStyle(
            "P", parent=base, fontName=_FONT_REGULAR, fontSize=11, leading=15,
            alignment=TA_LEFT, spaceAfter=6, textColor=colors.HexColor("#111111"),
        ),
        "li": ParagraphStyle(
            "LI", parent=base, fontName=_FONT_REGULAR, fontSize=11, leading=15,
            spaceAfter=2, textColor=colors.HexColor("#111111"),
        ),
        "quote": ParagraphStyle(
            "Quote", parent=base, fontName=_FONT_REGULAR, fontSize=10, leading=14,
            leftIndent=10, rightIndent=10, textColor=colors.HexColor("#444444"),
            backColor=colors.HexColor("#F4F8FE"),
            borderColor=colors.HexColor("#1B3A6B"), borderWidth=0, borderPadding=4,
        ),
    }


# ----------------------------------------------------------------------------
# HTML → Platypus parser. Markdown trả XHTML; chỉ cần handle elements common.
# ----------------------------------------------------------------------------

class _HtmlToFlowables(HTMLParser):
    """Convert HTML từ markdown package thành list Platypus flowables.

    Hỗ trợ: h1/h2/h3/h4, p, ul/ol/li, table/tr/td/th, blockquote, strong/b/em.
    Inline style trong Paragraph dùng reportlab markup `<b>...</b>` etc.
    """

    INLINE_TAGS = {"strong", "b", "em", "i", "code", "br"}

    def __init__(self, styles: dict[str, ParagraphStyle]):
        super().__init__()
        self.styles = styles
        self.flowables: list = []

        self._buffer = io.StringIO()  # text inline đang build.
        self._block_stack: list[str] = []  # stack: 'h1'/'p'/'li'/'quote'/...
        self._list_stack: list[list] = []  # stack for nested lists.
        self._table: list[list[str]] | None = None
        self._table_row: list[str] | None = None
        self._is_header_row = False

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag in ("h1", "h2", "h3", "h4"):
            self._flush_paragraph()
            # Map h4+ về h3 style.
            self._block_stack.append("h3" if tag == "h4" else tag)
        elif tag == "p":
            self._flush_paragraph()
            self._block_stack.append("p")
        elif tag == "blockquote":
            self._flush_paragraph()
            self._block_stack.append("quote")
        elif tag in ("ul", "ol"):
            self._flush_paragraph()
            self._list_stack.append([])
        elif tag == "li":
            self._flush_paragraph()
            self._block_stack.append("li")
        elif tag == "table":
            self._flush_paragraph()
            self._table = []
        elif tag == "thead":
            self._is_header_row = True
        elif tag == "tr":
            self._table_row = []
        elif tag in ("td", "th"):
            # th tag không cần đặc biệt — header row đã track qua thead.
            self._block_stack.append("cell")
            self._buffer = io.StringIO()
        elif tag in ("strong", "b"):
            self._buffer.write("<b>")
        elif tag in ("em", "i"):
            self._buffer.write("<i>")
        elif tag == "code":
            self._buffer.write("<font face='Courier'>")
        elif tag == "br":
            self._buffer.write("<br/>")

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag in ("h1", "h2", "h3", "h4"):
            self._emit_paragraph()
        elif tag == "p":
            self._emit_paragraph()
        elif tag == "blockquote":
            self._emit_paragraph()
        elif tag == "li":
            text = self._buffer.getvalue().strip()
            self._buffer = io.StringIO()
            if self._block_stack and self._block_stack[-1] == "li":
                self._block_stack.pop()
            if self._list_stack and text:
                para = Paragraph(text, self.styles["li"])
                self._list_stack[-1].append(ListItem(para, leftIndent=0))
        elif tag in ("ul", "ol"):
            if self._list_stack:
                items = self._list_stack.pop()
                if items:
                    self.flowables.append(ListFlowable(
                        items, bulletType="bullet" if tag == "ul" else "1",
                        leftIndent=18, bulletFontName=_FONT_REGULAR,
                    ))
                    self.flowables.append(Spacer(1, 4))
        elif tag in ("td", "th"):
            text = self._buffer.getvalue().strip()
            self._buffer = io.StringIO()
            if self._block_stack and self._block_stack[-1] == "cell":
                self._block_stack.pop()
            if self._table_row is not None:
                self._table_row.append(text)
        elif tag == "tr":
            if self._table is not None and self._table_row is not None:
                self._table.append(self._table_row)
            self._table_row = None
        elif tag == "thead":
            self._is_header_row = False
        elif tag == "table":
            self._emit_table()
        elif tag in ("strong", "b"):
            self._buffer.write("</b>")
        elif tag in ("em", "i"):
            self._buffer.write("</i>")
        elif tag == "code":
            self._buffer.write("</font>")

    def handle_data(self, data):
        # Escape XML chars cho reportlab markup safety.
        safe = (data
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;"))
        self._buffer.write(safe)

    def _flush_paragraph(self):
        """Khi gặp block mới, đẩy buffer text hiện tại nếu có."""
        text = self._buffer.getvalue().strip()
        self._buffer = io.StringIO()
        if not text or not self._block_stack:
            return
        block = self._block_stack[-1]
        if block in ("h1", "h2", "h3", "p", "quote"):
            self.flowables.append(Paragraph(text, self.styles[block]))

    def _emit_paragraph(self):
        text = self._buffer.getvalue().strip()
        self._buffer = io.StringIO()
        if self._block_stack:
            block = self._block_stack.pop()
            if text and block in self.styles:
                self.flowables.append(Paragraph(text, self.styles[block]))
                if block.startswith("h"):
                    self.flowables.append(Spacer(1, 2))
                else:
                    self.flowables.append(Spacer(1, 4))

    def _emit_table(self):
        if not self._table:
            self._table = None
            return
        # Wrap mỗi cell trong Paragraph để text wrap khi dài.
        cell_style = self.styles["li"]
        header_style = ParagraphStyle(
            "TH", parent=cell_style, fontName=_FONT_BOLD,
            textColor=colors.HexColor("#1B3A6B"),
        )
        wrapped = []
        for row_idx, row in enumerate(self._table):
            wrapped_row = []
            for cell in row:
                style = header_style if row_idx == 0 else cell_style
                wrapped_row.append(Paragraph(cell or "", style))
            wrapped.append(wrapped_row)

        table = Table(wrapped, repeatRows=1, hAlign="LEFT")
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#EBF2FB")),
            ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#C9D7EA")),
            ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#C9D7EA")),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 6),
            ("RIGHTPADDING", (0, 0), (-1, -1), 6),
            ("TOPPADDING", (0, 0), (-1, -1), 4),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ]))
        self.flowables.append(table)
        self.flowables.append(Spacer(1, 8))
        self._table = None


def render_markdown_to_pdf(markdown_text: str, *, title: str | None = None) -> bytes:
    """Convert markdown → PDF bytes. Raise `PdfRenderError` khi lỗi."""
    _register_fonts()

    html = md_lib.markdown(
        markdown_text or "",
        extensions=["tables", "fenced_code", "sane_lists"],
        output_format="xhtml",
    )

    styles = _build_styles()
    parser = _HtmlToFlowables(styles)
    try:
        parser.feed(html)
        # Flush block cuối nếu chưa close.
        parser._flush_paragraph()
    except Exception as ex:
        raise PdfRenderError(f"Parse markdown HTML lỗi: {ex}") from ex

    flowables = parser.flowables
    if not flowables:
        flowables = [Paragraph("(báo cáo trống)", styles["p"])]

    output = io.BytesIO()
    doc = SimpleDocTemplate(
        output,
        pagesize=A4,
        leftMargin=1.6 * cm, rightMargin=1.6 * cm,
        topMargin=1.8 * cm, bottomMargin=1.8 * cm,
        title=title or "Báo cáo Loca AI",
    )
    try:
        doc.build(flowables)
    except Exception as ex:
        raise PdfRenderError(f"Reportlab build PDF lỗi: {ex}") from ex

    output.seek(0)
    return output.getvalue()
