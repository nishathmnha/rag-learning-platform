$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-Color($hex, [int]$alpha = 255) {
  $clean = $hex.TrimStart("#")
  return [System.Drawing.Color]::FromArgb(
    $alpha,
    [Convert]::ToInt32($clean.Substring(0, 2), 16),
    [Convert]::ToInt32($clean.Substring(2, 2), 16),
    [Convert]::ToInt32($clean.Substring(4, 2), 16)
  )
}

function New-FontFamily($preferred, $fallback) {
  try {
    return [System.Drawing.FontFamily]::new($preferred)
  } catch {
    return [System.Drawing.FontFamily]::new($fallback)
  }
}

function New-Font($family, [float]$size, $style = [System.Drawing.FontStyle]::Regular) {
  return [System.Drawing.Font]::new($family, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function New-RoundedRectanglePath([float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $diameter = $radius * 2

  $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
  $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
  $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()

  return $path
}

function Fill-RoundedRectangle($graphics, $brush, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
  $path = New-RoundedRectanglePath $x $y $width $height $radius
  try {
    $graphics.FillPath($brush, $path)
  } finally {
    $path.Dispose()
  }
}

function Draw-RoundedRectangle($graphics, $pen, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
  $path = New-RoundedRectanglePath $x $y $width $height $radius
  try {
    $graphics.DrawPath($pen, $path)
  } finally {
    $path.Dispose()
  }
}

function Draw-TextBlock(
  $graphics,
  [string]$text,
  $font,
  $brush,
  [float]$x,
  [float]$y,
  [float]$width,
  [float]$height,
  [System.Drawing.StringAlignment]$alignment = [System.Drawing.StringAlignment]::Near,
  [System.Drawing.StringAlignment]$lineAlignment = [System.Drawing.StringAlignment]::Near
) {
  $text = $text -replace "\\n", "`n"
  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = $alignment
  $format.LineAlignment = $lineAlignment
  $format.Trimming = [System.Drawing.StringTrimming]::Word
  $format.FormatFlags = [System.Drawing.StringFormatFlags]::LineLimit
  try {
    $rect = [System.Drawing.RectangleF]::new($x, $y, $width, $height)
    $graphics.DrawString($text, $font, $brush, $rect, $format)
  } finally {
    $format.Dispose()
  }
}

function Draw-Card($graphics, [string]$title, [string]$body, [float]$x, [float]$y, [float]$width, [float]$height, $palette) {
  $fillBrush = [System.Drawing.SolidBrush]::new($palette.Card)
  $borderPen = [System.Drawing.Pen]::new($palette.CardBorder, 2)
  $titleBrush = [System.Drawing.SolidBrush]::new($palette.TextPrimary)
  $bodyBrush = [System.Drawing.SolidBrush]::new($palette.TextSecondary)

  try {
    Fill-RoundedRectangle $graphics $fillBrush $x $y $width $height 22
    Draw-RoundedRectangle $graphics $borderPen $x $y $width $height 22
    Draw-TextBlock $graphics $title $palette.Fonts.Semibold $titleBrush ($x + 24) ($y + 14) ($width - 48) 38
    if ($body.Trim().Length -gt 0) {
      Draw-TextBlock $graphics $body $palette.Fonts.Regular $bodyBrush ($x + 24) ($y + 46) ($width - 48) ($height - 58)
    }
  } finally {
    $fillBrush.Dispose()
    $borderPen.Dispose()
    $titleBrush.Dispose()
    $bodyBrush.Dispose()
  }
}

function Draw-Arrow($graphics, [float]$x1, [float]$y1, [float]$x2, [float]$y2, $color, [float]$width = 4) {
  $pen = [System.Drawing.Pen]::new($color, $width)
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::RoundAnchor
  try {
    $graphics.DrawLine($pen, $x1, $y1, $x2, $y2)
  } finally {
    $pen.Dispose()
  }
}

function Draw-DashedLine($graphics, [float]$x1, [float]$y1, [float]$x2, [float]$y2, $color) {
  $pen = [System.Drawing.Pen]::new($color, 2)
  $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
  try {
    $graphics.DrawLine($pen, $x1, $y1, $x2, $y2)
  } finally {
    $pen.Dispose()
  }
}

function Draw-ArrowLabel($graphics, [string]$text, [float]$x, [float]$y, [float]$width, $palette) {
  $fillBrush = [System.Drawing.SolidBrush]::new($palette.LabelFill)
  $borderPen = [System.Drawing.Pen]::new($palette.LabelBorder, 1.5)
  $textBrush = [System.Drawing.SolidBrush]::new($palette.TextPrimary)
  try {
    Fill-RoundedRectangle $graphics $fillBrush $x $y $width 34 17
    Draw-RoundedRectangle $graphics $borderPen $x $y $width 34 17
    Draw-TextBlock $graphics $text $palette.Fonts.Label $textBrush $x $y $width 34 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $fillBrush.Dispose()
    $borderPen.Dispose()
    $textBrush.Dispose()
  }
}

function Draw-CircleBadge($graphics, [string]$text, [float]$x, [float]$y, [float]$size, $fillColor, $textColor, $font) {
  $fillBrush = [System.Drawing.SolidBrush]::new($fillColor)
  $textBrush = [System.Drawing.SolidBrush]::new($textColor)
  try {
    $graphics.FillEllipse($fillBrush, $x, $y, $size, $size)
    Draw-TextBlock $graphics $text $font $textBrush $x $y $size $size ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $fillBrush.Dispose()
    $textBrush.Dispose()
  }
}

function New-Canvas([int]$width, [int]$height, $background) {
  $bitmap = [System.Drawing.Bitmap]::new($width, $height)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
  $graphics.Clear($background)
  return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Save-Canvas($canvas, [string]$path) {
  try {
    $canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $canvas.Graphics.Dispose()
    $canvas.Bitmap.Dispose()
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$outputDir = Join-Path $repoRoot "linkedin-assets"

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$palette = @{
  Background = New-Color "#F4F7FB"
  Surface = New-Color "#FFFFFF"
  Card = New-Color "#FFFFFF"
  CardBorder = New-Color "#D7E2F0"
  Navy = New-Color "#0B132B"
  Blue = New-Color "#2563EB"
  Teal = New-Color "#14B8A6"
  Amber = New-Color "#F59E0B"
  Rose = New-Color "#F97316"
  TextPrimary = New-Color "#10213A"
  TextSecondary = New-Color "#48617D"
  Muted = New-Color "#8AA0B8"
  LabelFill = New-Color "#EAF2FF"
  LabelBorder = New-Color "#B7CDF5"
}

$fontRegularFamily = New-FontFamily "Segoe UI" "Arial"
$fontSemiboldFamily = New-FontFamily "Segoe UI Semibold" "Arial"
$fontBoldFamily = New-FontFamily "Segoe UI Bold" "Arial"

$palette.Fonts = @{
  Hero = New-Font $fontBoldFamily 52 ([System.Drawing.FontStyle]::Bold)
  Title = New-Font $fontBoldFamily 34 ([System.Drawing.FontStyle]::Bold)
  Subtitle = New-Font $fontRegularFamily 22
  Semibold = New-Font $fontSemiboldFamily 24 ([System.Drawing.FontStyle]::Bold)
  Regular = New-Font $fontRegularFamily 18
  Small = New-Font $fontRegularFamily 16
  Tiny = New-Font $fontRegularFamily 14
  Label = New-Font $fontSemiboldFamily 15 ([System.Drawing.FontStyle]::Bold)
  Badge = New-Font $fontSemiboldFamily 18 ([System.Drawing.FontStyle]::Bold)
}

function Draw-Header($graphics, [string]$eyebrow, [string]$title, [string]$subtitle, [float]$width, $palette) {
  $eyebrowBrush = [System.Drawing.SolidBrush]::new($palette.Blue)
  $titleBrush = [System.Drawing.SolidBrush]::new($palette.TextPrimary)
  $subtitleBrush = [System.Drawing.SolidBrush]::new($palette.TextSecondary)
  try {
    Draw-TextBlock $graphics $eyebrow $palette.Fonts.Label $eyebrowBrush 72 44 ($width - 144) 28
    Draw-TextBlock $graphics $title $palette.Fonts.Title $titleBrush 72 82 ($width - 144) 52
    Draw-TextBlock $graphics $subtitle $palette.Fonts.Subtitle $subtitleBrush 72 138 ($width - 144) 72
  } finally {
    $eyebrowBrush.Dispose()
    $titleBrush.Dispose()
    $subtitleBrush.Dispose()
  }
}

function Draw-SequenceDiagram($path, $palette) {
  $canvas = New-Canvas 1800 1200 $palette.Background
  $g = $canvas.Graphics

  Draw-Header $g "LINKEDIN ASSET 01" "System Sequence Diagram" "End-to-end lesson ingestion, retrieval, and grounded generation across the TypeScript RAG platform." 1800 $palette

  $participants = @(
    @{ Label = "Learner"; X = 80; Color = $palette.Navy },
    @{ Label = "Next.js UI"; X = 320; Color = $palette.Blue },
    @{ Label = "Auth.js"; X = 560; Color = $palette.Teal },
    @{ Label = "Lesson APIs"; X = 800; Color = $palette.Amber },
    @{ Label = "Prisma + PostgreSQL"; X = 1040; Color = $palette.Rose },
    @{ Label = "OpenAI"; X = 1320; Color = $palette.Blue },
    @{ Label = "LanceDB"; X = 1560; Color = $palette.Teal }
  )

  foreach ($participant in $participants) {
    $brush = [System.Drawing.SolidBrush]::new($participant.Color)
    $textBrush = [System.Drawing.SolidBrush]::new($palette.Surface)
    try {
      Fill-RoundedRectangle $g $brush $participant.X 240 170 56 20
      Draw-TextBlock $g $participant.Label $palette.Fonts.Label $textBrush $participant.X 240 170 56 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
      Draw-DashedLine $g ($participant.X + 85) 296 ($participant.X + 85) 1080 $palette.Muted
    } finally {
      $brush.Dispose()
      $textBrush.Dispose()
    }
  }

  $events = @(
    @{ From = 0; To = 1; Y = 340; Label = "1. Sign in and open a lesson workspace"; Color = $palette.Navy; Width = 270 },
    @{ From = 1; To = 2; Y = 390; Label = "2. Validate session"; Color = $palette.Blue; Width = 170 },
    @{ From = 2; To = 1; Y = 440; Label = "3. Session ok"; Color = $palette.Teal; Width = 140 },
    @{ From = 0; To = 1; Y = 510; Label = "4. Upload PDF / DOCX / TXT or pasted text"; Color = $palette.Navy; Width = 300 },
    @{ From = 1; To = 3; Y = 560; Label = "5. POST /api/lessons/[id]/documents"; Color = $palette.Blue; Width = 260 },
    @{ From = 3; To = 4; Y = 620; Label = "6. Save lesson document + chunk rows"; Color = $palette.Amber; Width = 250 },
    @{ From = 3; To = 5; Y = 680; Label = "7. Create embeddings for chunks"; Color = $palette.Amber; Width = 210 },
    @{ From = 5; To = 3; Y = 730; Label = "8. Embedding vectors returned"; Color = $palette.Blue; Width = 190 },
    @{ From = 3; To = 6; Y = 790; Label = "9. Upsert vectors into lesson_chunks"; Color = $palette.Teal; Width = 240 },
    @{ From = 0; To = 1; Y = 860; Label = "10. Generate lesson / quiz / ask question"; Color = $palette.Navy; Width = 250 },
    @{ From = 1; To = 3; Y = 910; Label = "11. Call lesson, MCQ, or chat API"; Color = $palette.Blue; Width = 220 },
    @{ From = 3; To = 5; Y = 970; Label = "12. Embed query or lesson title"; Color = $palette.Amber; Width = 190 },
    @{ From = 3; To = 6; Y = 1020; Label = "13. Vector search for top relevant chunks"; Color = $palette.Teal; Width = 260 },
    @{ From = 3; To = 5; Y = 1070; Label = "14. Generate grounded answer / lesson / quiz"; Color = $palette.Rose; Width = 280 }
  )

  foreach ($event in $events) {
    $fromX = $participants[$event.From].X + 85
    $toX = $participants[$event.To].X + 85
    Draw-Arrow $g $fromX $event.Y $toX $event.Y $event.Color 4
    $labelX = [Math]::Min($fromX, $toX) + ([Math]::Abs($toX - $fromX) / 2) - ($event.Width / 2)
    Draw-ArrowLabel $g $event.Label $labelX ($event.Y - 32) $event.Width $palette
  }

  Draw-Card $g "Shared retrieval core" "The same chunk store powers lesson generation, MCQ generation, and chat. That keeps outputs consistent and source-grounded." 72 1100 840 76 $palette
  Draw-Card $g "Persistence split" "Prisma + PostgreSQL hold users, lessons, docs, chunks, generated lessons, and assessments. LanceDB stores vector-searchable chunk embeddings." 930 1100 798 76 $palette

  Save-Canvas $canvas $path
}

function Draw-Flowchart($path, $palette) {
  $canvas = New-Canvas 1800 1200 $palette.Background
  $g = $canvas.Graphics

  Draw-Header $g "LINKEDIN ASSET 02" "RAG System Flowchart" "How the TypeScript app ingests documents, builds lesson-scoped retrieval, and serves grounded learning experiences." 1800 $palette

  $nodes = @(
    @{ Name = "Start"; X = 120; Y = 270; W = 210; H = 72; Body = "Create or open a lesson"; Color = $palette.Navy },
    @{ Name = "Input"; X = 390; Y = 270; W = 290; H = 118; Body = "Upload PDF / DOCX / TXT\nor paste raw text"; Color = $palette.Blue },
    @{ Name = "Extract"; X = 760; Y = 270; W = 290; H = 118; Body = "Extract text\npdf-parse / mammoth / UTF-8 text"; Color = $palette.Teal },
    @{ Name = "Chunk"; X = 1120; Y = 270; W = 240; H = 118; Body = "Normalize and chunk text"; Color = $palette.Amber },
    @{ Name = "Embed"; X = 1430; Y = 270; W = 240; H = 118; Body = "Create embeddings\nOpenAI embeddings API"; Color = $palette.Rose },
    @{ Name = "Metadata"; X = 760; Y = 480; W = 280; H = 128; Body = "Persist lesson document\nand chunk metadata in PostgreSQL"; Color = $palette.Blue },
    @{ Name = "Vectors"; X = 1120; Y = 480; W = 280; H = 128; Body = "Upsert vectors into LanceDB\nfiltered by lessonId"; Color = $palette.Teal },
    @{ Name = "Requests"; X = 370; Y = 700; W = 350; H = 128; Body = "User requests:\nGenerate lesson, generate MCQ,\nor chat with lesson"; Color = $palette.Navy },
    @{ Name = "Retrieve"; X = 840; Y = 700; W = 320; H = 128; Body = "Embed request query and\nretrieve top relevant chunks"; Color = $palette.Amber },
    @{ Name = "Generate"; X = 1280; Y = 700; W = 320; H = 128; Body = "Generate grounded output\nwith OpenAI responses API"; Color = $palette.Rose },
    @{ Name = "Return"; X = 840; Y = 930; W = 420; H = 132; Body = "Return readable lesson,\nMCQs, or chat answer\nwith source references"; Color = $palette.Blue }
  )

  foreach ($node in $nodes) {
    $fillBrush = [System.Drawing.SolidBrush]::new($node.Color)
    $overlayBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
    $titleBrush = [System.Drawing.SolidBrush]::new($palette.Surface)
    $bodyBrush = [System.Drawing.SolidBrush]::new($palette.Surface)
    try {
      Fill-RoundedRectangle $g $fillBrush $node.X $node.Y $node.W $node.H 26
      Fill-RoundedRectangle $g $overlayBrush ($node.X + 2) ($node.Y + 36) ($node.W - 4) ($node.H - 38) 24
      Draw-TextBlock $g $node.Name $palette.Fonts.Label $titleBrush ($node.X + 20) ($node.Y + 8) ($node.W - 40) 28
      Draw-TextBlock $g $node.Body $palette.Fonts.Regular ([System.Drawing.SolidBrush]::new($palette.TextPrimary)) ($node.X + 22) ($node.Y + 48) ($node.W - 44) ($node.H - 60)
    } finally {
      $fillBrush.Dispose()
      $overlayBrush.Dispose()
      $titleBrush.Dispose()
    }
  }

  Draw-Arrow $g 330 306 390 306 $palette.Blue 5
  Draw-Arrow $g 680 329 760 329 $palette.Teal 5
  Draw-Arrow $g 1050 329 1120 329 $palette.Amber 5
  Draw-Arrow $g 1360 329 1430 329 $palette.Rose 5
  Draw-Arrow $g 900 388 900 480 $palette.Blue 5
  Draw-Arrow $g 1240 388 1240 480 $palette.Teal 5
  Draw-Arrow $g 680 764 840 764 $palette.Amber 5
  Draw-Arrow $g 1160 764 1280 764 $palette.Rose 5
  Draw-Arrow $g 1440 828 1080 930 $palette.Blue 5
  Draw-Arrow $g 1040 608 1000 700 $palette.Amber 5
  Draw-Arrow $g 1260 608 1260 700 $palette.Teal 5

  Draw-ArrowLabel $g "ingestion pipeline" 778 424 190 $palette
  Draw-ArrowLabel $g "retrieval layer" 866 640 150 $palette
  Draw-ArrowLabel $g "grounded generation" 1278 642 190 $palette

  Draw-Card $g "Why it matters for RAG" "Every generated artifact is lesson-scoped. The user can upload new documents, regenerate outputs, and keep the system grounded in a changing corpus without changing the product flow." 72 1082 1656 88 $palette

  Save-Canvas $canvas $path
}

function Draw-Chip($graphics, [string]$text, [float]$x, [float]$y, [float]$width, $fill, $textColor, $palette) {
  $fillBrush = [System.Drawing.SolidBrush]::new($fill)
  $textBrush = [System.Drawing.SolidBrush]::new($textColor)
  try {
    Fill-RoundedRectangle $graphics $fillBrush $x $y $width 44 22
    Draw-TextBlock $graphics $text $palette.Fonts.Label $textBrush $x $y $width 44 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $fillBrush.Dispose()
    $textBrush.Dispose()
  }
}

function Draw-Thumbnail($path, $palette) {
  $canvas = New-Canvas 1600 900 $palette.Navy
  $g = $canvas.Graphics

  $gradientRect = [System.Drawing.Rectangle]::new(0, 0, 1600, 900)
  $gradientBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    $gradientRect,
    [System.Drawing.Color]::FromArgb(255, 11, 19, 43),
    [System.Drawing.Color]::FromArgb(255, 22, 60, 102),
    35.0
  )

  try {
    $g.FillRectangle($gradientBrush, $gradientRect)
  } finally {
    $gradientBrush.Dispose()
  }

  $accentBrush1 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(40, 56, 189, 248))
  $accentBrush2 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 20, 184, 166))
  try {
    $g.FillEllipse($accentBrush1, 980, 70, 460, 460)
    $g.FillEllipse($accentBrush2, 1120, 460, 340, 340)
  } finally {
    $accentBrush1.Dispose()
    $accentBrush2.Dispose()
  }

  $heroBrush = [System.Drawing.SolidBrush]::new($palette.Surface)
  $subBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 226, 232, 240))
  try {
    Draw-TextBlock $g "Built a TypeScript RAG Learning Platform" $palette.Fonts.Hero $heroBrush 86 96 760 188
    Draw-TextBlock $g "Exploring the TypeScript LLM stack with Next.js, Prisma, OpenAI, and LanceDB through a learning-first RAG product." $palette.Fonts.Subtitle $subBrush 92 294 700 120
  } finally {
    $heroBrush.Dispose()
    $subBrush.Dispose()
  }

  Draw-Chip $g "Multi-file ingestion" 90 438 214 $palette.Teal $palette.Surface $palette
  Draw-Chip $g "Shared retrieval core" 322 438 226 $palette.Blue $palette.Surface $palette
  Draw-Chip $g "Grounded lessons + MCQs + chat" 568 438 330 $palette.Amber $palette.Navy $palette

  $panelBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
  $panelBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(80, 200, 214, 230), 2)
  try {
    Fill-RoundedRectangle $g $panelBrush 900 120 612 620 28
    Draw-RoundedRectangle $g $panelBorder 900 120 612 620 28
  } finally {
    $panelBrush.Dispose()
    $panelBorder.Dispose()
  }

  Draw-Card $g "Documents" "PDF, DOCX, TXT, pasted text" 948 184 210 104 $palette
  Draw-Card $g "Embeddings" "OpenAI embeddings API" 1224 184 210 104 $palette
  Draw-Card $g "Prisma + Postgres" "Users, lessons, documents, chunks, quizzes" 948 340 230 132 $palette
  Draw-Card $g "LanceDB" "lesson_chunks vector store" 1216 340 210 132 $palette
  Draw-Card $g "Outputs" "Lesson generation\nMCQ generation\nGrounded chat with sources" 1088 540 268 150 $palette

  Draw-Arrow $g 1158 236 1224 236 $palette.Blue 4
  Draw-Arrow $g 1054 288 1054 340 $palette.Teal 4
  Draw-Arrow $g 1328 288 1328 340 $palette.Amber 4
  Draw-Arrow $g 1163 472 1163 540 $palette.Rose 4
  Draw-Arrow $g 1320 472 1220 540 $palette.Blue 4

  Draw-ArrowLabel $g "ingest" 1172 214 86 $palette
  Draw-ArrowLabel $g "metadata" 1000 308 104 $palette
  Draw-ArrowLabel $g "vectors" 1280 308 92 $palette
  Draw-ArrowLabel $g "retrieve + generate" 1114 498 200 $palette

  $footerBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(210, 226, 232, 240))
  try {
    Draw-TextBlock $g "LangChain / LangGraph / Spring AI background -> exploring the TypeScript-native LLM stack" $palette.Fonts.Small $footerBrush 92 792 1180 32
  } finally {
    $footerBrush.Dispose()
  }

  Draw-CircleBadge $g "TS" 86 52 44 $palette.Surface $palette.Navy $palette.Fonts.Badge

  Save-Canvas $canvas $path
}

$sequencePath = Join-Path $outputDir "rag-system-sequence-diagram.png"
$flowchartPath = Join-Path $outputDir "rag-system-flowchart.png"
$thumbnailPath = Join-Path $outputDir "linkedin-thumbnail.png"
$captionPath = Join-Path $outputDir "linkedin-caption.txt"
$readmePath = Join-Path $outputDir "README.md"

Draw-SequenceDiagram $sequencePath $palette
Draw-Flowchart $flowchartPath $palette
Draw-Thumbnail $thumbnailPath $palette

$caption = @'
Built a TypeScript RAG learning platform to explore a different side of the LLM stack.

I have spent a lot of time working with LangChain, LangGraph, Spring AI, and production RAG patterns, but I wanted to go deeper on the TypeScript path and build the core pieces myself:

- Next.js App Router for the UI and API layer
- Prisma + PostgreSQL for users, lessons, documents, generated lessons, and MCQs
- LanceDB for lesson-scoped vector retrieval
- OpenAI embeddings + generation APIs for ingestion, lesson generation, quizzes, and grounded chat

What I liked about this build was the simplicity of the architecture:
- multi-file document ingestion
- shared retrieval across lesson generation, quiz generation, and chat
- source-grounded responses instead of generic chatbot output

It was a good reminder that solid RAG systems are less about hype and more about disciplined data flow, retrieval boundaries, and product UX.

#TypeScript #RAG #LLM #NextJS #OpenAI #Prisma #PostgreSQL #LanceDB #GenAI #SoftwareEngineering
'@

Set-Content -Path $captionPath -Value $caption -Encoding UTF8

$readme = @'
# LinkedIn Assets

Generated assets for sharing the TypeScript RAG Learning Platform on LinkedIn.

Files:
- `rag-system-sequence-diagram.png`
- `rag-system-flowchart.png`
- `linkedin-thumbnail.png`
- `linkedin-caption.txt`

Generated from:
- `scripts/generate-linkedin-assets.ps1`
'@

Set-Content -Path $readmePath -Value $readme -Encoding UTF8

Write-Host "Created LinkedIn assets in: $outputDir"
