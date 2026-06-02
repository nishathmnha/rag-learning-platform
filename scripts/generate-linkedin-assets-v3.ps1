$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Color($hex, [int]$alpha = 255) {
  $clean = $hex.TrimStart("#")
  return [System.Drawing.Color]::FromArgb(
    $alpha,
    [Convert]::ToInt32($clean.Substring(0, 2), 16),
    [Convert]::ToInt32($clean.Substring(2, 2), 16),
    [Convert]::ToInt32($clean.Substring(4, 2), 16)
  )
}

function Family($name, $fallback) {
  try {
    return [System.Drawing.FontFamily]::new($name)
  } catch {
    return [System.Drawing.FontFamily]::new($fallback)
  }
}

function Font($family, [float]$size, $style = [System.Drawing.FontStyle]::Regular) {
  return [System.Drawing.Font]::new($family, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Canvas([int]$width, [int]$height, $bg) {
  $bitmap = [System.Drawing.Bitmap]::new($width, $height)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
  $graphics.Clear($bg)
  return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Save($canvas, [string]$path) {
  try {
    $canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $canvas.Graphics.Dispose()
    $canvas.Bitmap.Dispose()
  }
}

function RectPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 8) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function FillRound($g, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 8) {
  $path = RectPath $x $y $w $h $r
  try {
    $g.FillPath($brush, $path)
  } finally {
    $path.Dispose()
  }
}

function StrokeRound($g, $pen, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 8) {
  $path = RectPath $x $y $w $h $r
  try {
    $g.DrawPath($pen, $path)
  } finally {
    $path.Dispose()
  }
}

function Text(
  $g,
  [string]$content,
  $font,
  $brush,
  [float]$x,
  [float]$y,
  [float]$w,
  [float]$h,
  [System.Drawing.StringAlignment]$align = [System.Drawing.StringAlignment]::Near,
  [System.Drawing.StringAlignment]$line = [System.Drawing.StringAlignment]::Near
) {
  $content = $content -replace "\\n", "`n"
  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = $align
  $format.LineAlignment = $line
  $format.Trimming = [System.Drawing.StringTrimming]::Word
  $format.FormatFlags = [System.Drawing.StringFormatFlags]::LineLimit
  try {
    $g.DrawString($content, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $format)
  } finally {
    $format.Dispose()
  }
}

function Line($g, [float]$x1, [float]$y1, [float]$x2, [float]$y2, $color, [float]$width = 4, [bool]$arrow = $false) {
  $pen = [System.Drawing.Pen]::new($color, $width)
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

  if ($arrow) {
    $cap = [System.Drawing.Drawing2D.AdjustableArrowCap]::new(8, 9)
    $pen.CustomEndCap = $cap
  }

  try {
    $g.DrawLine($pen, $x1, $y1, $x2, $y2)
  } finally {
    if ($arrow) {
      $cap.Dispose()
    }
    $pen.Dispose()
  }
}

function Connector($g, [float[]]$points, $color, [float]$width = 4) {
  for ($i = 0; $i -lt ($points.Length / 2) - 2; $i += 1) {
    $p = $i * 2
    Line $g $points[$p] $points[$p + 1] $points[$p + 2] $points[$p + 3] $color $width $false
  }

  $last = $points.Length - 4
  Line $g $points[$last] $points[$last + 1] $points[$last + 2] $points[$last + 3] $color $width $true
}

function Background($g, $palette, [int]$width, [int]$height) {
  $dot = [System.Drawing.SolidBrush]::new($palette.Grid)
  try {
    for ($x = 36; $x -lt $width; $x += 56) {
      for ($y = 36; $y -lt $height; $y += 56) {
        $g.FillEllipse($dot, $x, $y, 2.2, 2.2)
      }
    }
  } finally {
    $dot.Dispose()
  }
}

function Header($g, $palette, [string]$tag, [string]$title, [string]$subtitle, [string]$number) {
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $accent = [System.Drawing.SolidBrush]::new($palette.Teal)
  try {
    Text $g $tag $palette.Fonts.Tag $accent 80 70 520 30
    Text $g $number $palette.Fonts.Small $muted 850 70 150 30 ([System.Drawing.StringAlignment]::Far)
    Text $g $title $palette.Fonts.Title $ink 80 118 900 116
    Text $g $subtitle $palette.Fonts.Body $muted 82 250 860 72
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $accent.Dispose()
  }
}

function Pill($g, $palette, [string]$label, [float]$x, [float]$y, [float]$w, $fill, $textColor = $null) {
  if ($null -eq $textColor) {
    $textColor = $palette.Ink
  }

  $b = [System.Drawing.SolidBrush]::new($fill)
  $t = [System.Drawing.SolidBrush]::new($textColor)
  try {
    FillRound $g $b $x $y $w 42 21
    Text $g $label $palette.Fonts.Pill $t $x $y $w 42 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $b.Dispose()
    $t.Dispose()
  }
}

function Card($g, $palette, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent) {
  $shadow = [System.Drawing.SolidBrush]::new($palette.Shadow)
  $surface = [System.Drawing.SolidBrush]::new($palette.Surface)
  $border = [System.Drawing.Pen]::new($palette.Border, 2)
  $accentBrush = [System.Drawing.SolidBrush]::new($accent)
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)

  try {
    FillRound $g $shadow ($x + 7) ($y + 8) $w $h 8
    FillRound $g $surface $x $y $w $h 8
    StrokeRound $g $border $x $y $w $h 8
    $g.FillRectangle($accentBrush, $x, $y, 8, $h)
    Text $g $title $palette.Fonts.CardTitle $ink ($x + 26) ($y + 18) ($w - 48) 34
    Text $g $body $palette.Fonts.CardBody $muted ($x + 26) ($y + 58) ($w - 48) ($h - 70)
  } finally {
    $shadow.Dispose()
    $surface.Dispose()
    $border.Dispose()
    $accentBrush.Dispose()
    $ink.Dispose()
    $muted.Dispose()
  }
}

function StepCard($g, $palette, [string]$num, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent) {
  Card $g $palette $title $body $x $y $w $h $accent
  $badge = [System.Drawing.SolidBrush]::new($accent)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  try {
    $g.FillEllipse($badge, ($x + $w - 52), ($y + 18), 34, 34)
    Text $g $num $palette.Fonts.Badge $white ($x + $w - 52) ($y + 18) 34 34 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $badge.Dispose()
    $white.Dispose()
  }
}

function Footer($g, $palette, [string]$text) {
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  try {
    Text $g $text $palette.Fonts.Small $muted 80 1270 920 40
  } finally {
    $muted.Dispose()
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$outputDir = Join-Path $repoRoot "linkedin-assets-v3"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$regular = Family "Segoe UI" "Arial"
$semibold = Family "Segoe UI Semibold" "Arial"
$black = Family "Segoe UI Black" "Arial"

$palette = @{
  Paper = Color "#FAFAF2"
  Surface = Color "#FFFFFF"
  Ink = Color "#101418"
  Muted = Color "#566575"
  Border = Color "#D8E0DC"
  Shadow = Color "#D5E0D8" 120
  Grid = Color "#DDE8DD" 150
  White = Color "#FFFFFF"
  Teal = Color "#04786F"
  Blue = Color "#2F65D9"
  Coral = Color "#F36855"
  Amber = Color "#F3B63F"
  Lime = Color "#A6EA2F"
  Slate = Color "#17212B"
}

$palette.Fonts = @{
  Tag = Font $semibold 22 ([System.Drawing.FontStyle]::Bold)
  Title = Font $black 58 ([System.Drawing.FontStyle]::Bold)
  Hero = Font $black 74 ([System.Drawing.FontStyle]::Bold)
  Body = Font $regular 26
  CardTitle = Font $semibold 25 ([System.Drawing.FontStyle]::Bold)
  CardBody = Font $regular 20
  Small = Font $regular 18
  Pill = Font $semibold 18 ([System.Drawing.FontStyle]::Bold)
  Badge = Font $semibold 17 ([System.Drawing.FontStyle]::Bold)
  Lane = Font $semibold 20 ([System.Drawing.FontStyle]::Bold)
  Event = Font $regular 18
}

function Draw-Cover($path, $palette) {
  $canvas = Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Background $g $palette 1080 1350

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  $teal = [System.Drawing.SolidBrush]::new($palette.Teal)

  try {
    FillRound $g $teal 80 74 110 48 24
    Text $g "TS RAG" $palette.Fonts.Pill $white 80 74 110 48 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Text $g "01 / 03" $palette.Fonts.Small $muted 850 82 150 30 ([System.Drawing.StringAlignment]::Far)
    Text $g "TypeScript RAG\nLearning Platform" $palette.Fonts.Hero $ink 80 178 900 210
    Text $g "A learning-first RAG app built while exploring the TypeScript LLM ecosystem, including Vercel AI SDK patterns." $palette.Fonts.Body $muted 82 420 880 100

    Pill $g $palette "Next.js App Router" 82 560 218 $palette.Lime
    Pill $g $palette "OpenAI SDK" 322 560 150 $palette.Amber
    Pill $g $palette "Vercel AI SDK ecosystem" 494 560 276 $palette.Coral $palette.White

    $panel = [System.Drawing.SolidBrush]::new($palette.Surface)
    $border = [System.Drawing.Pen]::new($palette.Border, 2)
    FillRound $g $panel 92 704 896 432 10
    StrokeRound $g $border 92 704 896 432 10
    $panel.Dispose()
    $border.Dispose()

    Card $g $palette "Ingest" "PDF, DOCX, TXT" 144 780 222 116 $palette.Teal
    Card $g $palette "Index" "Chunks + vectors" 430 780 222 116 $palette.Blue
    Card $g $palette "Retrieve" "Lesson chunks" 716 780 222 116 $palette.Amber
    Card $g $palette "Generate" "Outputs" 430 964 222 116 $palette.Coral

    Connector $g ([float[]]@(366, 838, 430, 838)) $palette.Teal 5
    Connector $g ([float[]]@(652, 838, 716, 838)) $palette.Blue 5
    Connector $g ([float[]]@(827, 896, 827, 926, 541, 926, 541, 964)) $palette.Amber 5

    Text $g "LangChain / LangGraph / Spring AI background -> TypeScript-native LLM exploration" $palette.Fonts.Small $muted 82 1232 840 34
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $white.Dispose()
    $teal.Dispose()
  }

  Save $canvas $path
}

function Draw-Flowchart($path, $palette) {
  $canvas = Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Background $g $palette 1080 1350
  Header $g $palette "RAG FLOWCHART" "Clean RAG pipeline" "A single ingestion path feeds a reusable retrieval core for lessons, quizzes, and chat." "02 / 03"

  $x = 330
  $w = 420
  $h = 96
  $ys = @(360, 496, 632, 768, 956, 1092)

  StepCard $g $palette "1" "Upload sources" "PDF, DOCX, TXT, or pasted text" $x $ys[0] $w $h $palette.Teal
  StepCard $g $palette "2" "Extract and chunk" "Readable text becomes retrieval units" $x $ys[1] $w $h $palette.Blue
  StepCard $g $palette "3" "Embed chunks" "OpenAI vector embeddings" $x $ys[2] $w $h $palette.Coral

  $storeY = $ys[3]
  Card $g $palette "PostgreSQL" "Lesson metadata\nDocuments\nAssessments" 92 $storeY 370 132 $palette.Blue
  Card $g $palette "LanceDB" "lesson_chunks\nVector search" 618 $storeY 370 132 $palette.Teal

  StepCard $g $palette "4" "Retrieve context" "Query embedding -> top relevant chunks" $x $ys[4] $w $h $palette.Amber
  StepCard $g $palette "5" "Generate output" "Grounded lesson, MCQ quiz, or answer" $x $ys[5] $w $h $palette.Coral

  Connector $g ([float[]]@(540, 456, 540, 496)) $palette.Teal 5
  Connector $g ([float[]]@(540, 592, 540, 632)) $palette.Blue 5
  Connector $g ([float[]]@(540, 728, 540, 752, 277, 752, 277, 768)) $palette.Blue 5
  Connector $g ([float[]]@(540, 728, 540, 752, 803, 752, 803, 768)) $palette.Teal 5
  Connector $g ([float[]]@(277, 900, 277, 928, 540, 928, 540, 956)) $palette.Blue 5
  Connector $g ([float[]]@(803, 900, 803, 928, 540, 928, 540, 956)) $palette.Teal 5
  Connector $g ([float[]]@(540, 1052, 540, 1092)) $palette.Amber 5

  $note = [System.Drawing.SolidBrush]::new($palette.Slate)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  try {
    FillRound $g $note 92 1230 896 64 8
    Text $g "The important part: lessons, MCQs, and chat all share the same retrieval layer." $palette.Fonts.CardBody $white 126 1246 828 34
  } finally {
    $note.Dispose()
    $white.Dispose()
  }

  Save $canvas $path
}

function Draw-Sequence($path, $palette) {
  $canvas = Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Background $g $palette 1080 1350
  Header $g $palette "SEQUENCE DIAGRAM" "System sequence" "The full product path, from authenticated user action to grounded output." "03 / 03"

  $lanes = @(
    @{ Label = "User"; X = 104; C = $palette.Slate },
    @{ Label = "Next.js UI"; X = 292; C = $palette.Blue },
    @{ Label = "API routes"; X = 480; C = $palette.Amber },
    @{ Label = "OpenAI"; X = 668; C = $palette.Coral },
    @{ Label = "Data stores"; X = 856; C = $palette.Teal }
  )

  foreach ($lane in $lanes) {
    $fill = [System.Drawing.SolidBrush]::new($lane.C)
    $white = [System.Drawing.SolidBrush]::new($palette.White)
    $dash = [System.Drawing.Pen]::new($palette.Border, 2)
    $dash.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    try {
      FillRound $g $fill ($lane.X - 70) 352 140 46 8
      Text $g $lane.Label $palette.Fonts.Lane $white ($lane.X - 70) 352 140 46 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
      $g.DrawLine($dash, $lane.X, 414, $lane.X, 1132)
    } finally {
      $fill.Dispose()
      $white.Dispose()
      $dash.Dispose()
    }
  }

  $events = @(
    @{ A = 0; B = 1; Y = 462; L = "Open lesson workspace"; C = $palette.Slate },
    @{ A = 1; B = 2; Y = 548; L = "Validate session"; C = $palette.Blue },
    @{ A = 0; B = 1; Y = 650; L = "Upload documents"; C = $palette.Slate },
    @{ A = 1; B = 2; Y = 736; L = "POST documents"; C = $palette.Blue },
    @{ A = 2; B = 3; Y = 822; L = "Create embeddings"; C = $palette.Coral },
    @{ A = 2; B = 4; Y = 908; L = "Save metadata + vectors"; C = $palette.Teal },
    @{ A = 0; B = 1; Y = 1010; L = "Generate request"; C = $palette.Slate },
    @{ A = 2; B = 4; Y = 1096; L = "Retrieve + generate"; C = $palette.Amber }
  )

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  foreach ($event in $events) {
    $x1 = $lanes[$event.A].X
    $x2 = $lanes[$event.B].X
    $labelX = [Math]::Min($x1, $x2)
    $labelW = [Math]::Max([Math]::Abs($x2 - $x1), 240)
    $labelX = $labelX - (($labelW - [Math]::Abs($x2 - $x1)) / 2)
    Text $g $event.L $palette.Fonts.Event $ink $labelX ($event.Y - 34) $labelW 28 ([System.Drawing.StringAlignment]::Center)
    Connector $g ([float[]]@($x1, $event.Y, $x2, $event.Y)) $event.C 4
  }
  $ink.Dispose()

  Card $g $palette "Design choice" "PostgreSQL stores app state. LanceDB stores vectors. Both stay scoped by lessonId." 110 1180 860 112 $palette.Teal

  Save $canvas $path
}

function Draw-Thumbnail($path, $palette) {
  $canvas = Canvas 1600 900 $palette.Paper
  $g = $canvas.Graphics
  Background $g $palette 1600 900

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  $teal = [System.Drawing.SolidBrush]::new($palette.Teal)
  try {
    FillRound $g $teal 92 78 134 54 27
    Text $g "TS RAG" $palette.Fonts.Pill $white 92 78 134 54 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Text $g "TypeScript RAG\nLearning Platform" $palette.Fonts.Hero $ink 92 176 760 176
    Text $g "Next.js, OpenAI SDK, Prisma, LanceDB, and the Vercel AI SDK ecosystem." $palette.Fonts.Body $muted 98 390 760 70

    Pill $g $palette "Document ingestion" 98 508 232 $palette.Lime
    Pill $g $palette "Vector retrieval" 354 508 210 $palette.Amber
    Pill $g $palette "Grounded learning outputs" 588 508 310 $palette.Coral $palette.White

    Card $g $palette "Sources" "PDF / DOCX / TXT" 990 116 240 112 $palette.Teal
    Card $g $palette "Embeddings" "OpenAI vectors" 1280 116 240 112 $palette.Coral
    Card $g $palette "PostgreSQL" "App state" 990 330 240 112 $palette.Blue
    Card $g $palette "LanceDB" "Vector store" 1280 330 240 112 $palette.Teal
    Card $g $palette "Outputs" "Lessons, MCQs, chat" 1135 590 260 126 $palette.Amber

    Connector $g ([float[]]@(1230, 172, 1280, 172)) $palette.Teal 5
    Connector $g ([float[]]@(1110, 228, 1110, 330)) $palette.Blue 5
    Connector $g ([float[]]@(1400, 228, 1400, 330)) $palette.Coral 5
    Connector $g ([float[]]@(1110, 442, 1110, 510, 1265, 510, 1265, 590)) $palette.Blue 5
    Connector $g ([float[]]@(1400, 442, 1400, 510, 1265, 510, 1265, 590)) $palette.Teal 5

    Text $g "Built after LangChain, LangGraph, and Spring AI - exploring the TypeScript-native LLM path." $palette.Fonts.Small $muted 98 796 900 38
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $white.Dispose()
    $teal.Dispose()
  }

  Save $canvas $path
}

$cover = Join-Path $outputDir "01-cover-typescript-rag-platform.png"
$flowchart = Join-Path $outputDir "02-rag-flowchart.png"
$sequence = Join-Path $outputDir "03-system-sequence-diagram.png"
$thumbnail = Join-Path $outputDir "linkedin-thumbnail.png"
$captionPath = Join-Path $outputDir "linkedin-caption.txt"
$readmePath = Join-Path $outputDir "README.md"

Draw-Cover $cover $palette
Draw-Flowchart $flowchart $palette
Draw-Sequence $sequence $palette
Draw-Thumbnail $thumbnail $palette

$caption = @'
I have built RAG systems with LangChain, LangGraph, and Spring AI, so I wanted to explore the TypeScript-native LLM path more intentionally.

This build is a small RAG learning platform:

- Next.js App Router for the UI and API routes
- OpenAI SDK for embeddings and generation
- Prisma + PostgreSQL for users, lessons, documents, generated lessons, and MCQs
- LanceDB for lesson-scoped vector retrieval
- Vercel AI SDK ecosystem as the TypeScript-native direction I wanted to explore and compare against

The architecture is intentionally simple:

One document ingestion pipeline.
One lesson-scoped retrieval layer.
Three learning outputs: generated lessons, MCQ assessments, and grounded chat answers with source references.

The big reminder for me: good RAG is product engineering first. Clean boundaries, traceable sources, predictable retrieval, and a UI that makes the AI useful.

#TypeScript #RAG #LLM #VercelAI #NextJS #OpenAI #Prisma #PostgreSQL #LanceDB #GenAI #SoftwareEngineering
'@

$readme = @'
# LinkedIn Assets V3

Cleaner LinkedIn-ready PNG assets for the TypeScript RAG Learning Platform.

Files:
- `01-cover-typescript-rag-platform.png`
- `02-rag-flowchart.png`
- `03-system-sequence-diagram.png`
- `linkedin-thumbnail.png`
- `linkedin-caption.txt`

Generated from:
- `scripts/generate-linkedin-assets-v3.ps1`
'@

Set-Content -Path $captionPath -Value $caption -Encoding UTF8
Set-Content -Path $readmePath -Value $readme -Encoding UTF8

Write-Host "Created v3 LinkedIn assets in: $outputDir"
