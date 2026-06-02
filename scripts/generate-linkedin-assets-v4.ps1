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

function New-Family($name, $fallback) {
  try {
    return [System.Drawing.FontFamily]::new($name)
  } catch {
    return [System.Drawing.FontFamily]::new($fallback)
  }
}

function New-Font($family, [float]$size, $style = [System.Drawing.FontStyle]::Regular) {
  return [System.Drawing.Font]::new($family, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function New-Canvas([int]$width, [int]$height, $bg) {
  $bitmap = [System.Drawing.Bitmap]::new($width, $height)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
  $graphics.Clear($bg)
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

function New-RoundPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 8) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function Fill-Round($g, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 8) {
  $path = New-RoundPath $x $y $w $h $r
  try {
    $g.FillPath($brush, $path)
  } finally {
    $path.Dispose()
  }
}

function Stroke-Round($g, $pen, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 8) {
  $path = New-RoundPath $x $y $w $h $r
  try {
    $g.DrawPath($pen, $path)
  } finally {
    $path.Dispose()
  }
}

function Draw-Text(
  $g,
  [string]$text,
  $font,
  $brush,
  [float]$x,
  [float]$y,
  [float]$w,
  [float]$h,
  [System.Drawing.StringAlignment]$align = [System.Drawing.StringAlignment]::Near,
  [System.Drawing.StringAlignment]$line = [System.Drawing.StringAlignment]::Near
) {
  $text = $text -replace "\\n", "`n"
  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = $align
  $format.LineAlignment = $line
  $format.Trimming = [System.Drawing.StringTrimming]::Word
  $format.FormatFlags = [System.Drawing.StringFormatFlags]::LineLimit
  try {
    $g.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $format)
  } finally {
    $format.Dispose()
  }
}

function Draw-Line($g, [float]$x1, [float]$y1, [float]$x2, [float]$y2, $color, [float]$width = 4, [bool]$arrow = $false) {
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

function Draw-Connector($g, [float[]]$points, $color, [float]$width = 4) {
  for ($i = 0; $i -lt ($points.Length / 2) - 2; $i += 1) {
    $p = $i * 2
    Draw-Line $g $points[$p] $points[$p + 1] $points[$p + 2] $points[$p + 3] $color $width $false
  }

  $last = $points.Length - 4
  Draw-Line $g $points[$last] $points[$last + 1] $points[$last + 2] $points[$last + 3] $color $width $true
}

function Draw-Background($g, $palette, [int]$width, [int]$height) {
  $dot = [System.Drawing.SolidBrush]::new($palette.Grid)
  $line = [System.Drawing.Pen]::new($palette.Rule, 1)
  try {
    for ($x = 48; $x -lt $width; $x += 64) {
      for ($y = 48; $y -lt $height; $y += 64) {
        $g.FillEllipse($dot, $x, $y, 2, 2)
      }
    }

    $g.DrawLine($line, 80, 1320, $width - 80, 1320)
  } finally {
    $dot.Dispose()
    $line.Dispose()
  }
}

function Draw-Header($g, $palette, [string]$eyebrow, [string]$title, [string]$subtitle, [string]$page) {
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $accent = [System.Drawing.SolidBrush]::new($palette.Teal)
  try {
    Draw-Text $g $eyebrow $palette.Fonts.Eyebrow $accent 80 68 560 30
    Draw-Text $g $page $palette.Fonts.Small $muted 850 68 150 30 ([System.Drawing.StringAlignment]::Far)
    Draw-Text $g $title $palette.Fonts.Title $ink 80 124 900 124
    Draw-Text $g $subtitle $palette.Fonts.Body $muted 82 262 870 82
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $accent.Dispose()
  }
}

function Draw-Pill($g, $palette, [string]$text, [float]$x, [float]$y, [float]$w, $fill, $textColor = $null) {
  if ($null -eq $textColor) {
    $textColor = $palette.Ink
  }

  $fillBrush = [System.Drawing.SolidBrush]::new($fill)
  $textBrush = [System.Drawing.SolidBrush]::new($textColor)
  try {
    Fill-Round $g $fillBrush $x $y $w 42 21
    Draw-Text $g $text $palette.Fonts.Pill $textBrush $x $y $w 42 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $fillBrush.Dispose()
    $textBrush.Dispose()
  }
}

function Draw-Card($g, $palette, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent) {
  $shadow = [System.Drawing.SolidBrush]::new($palette.Shadow)
  $surface = [System.Drawing.SolidBrush]::new($palette.Surface)
  $border = [System.Drawing.Pen]::new($palette.Border, 1.6)
  $accentBrush = [System.Drawing.SolidBrush]::new($accent)
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)

  try {
    Fill-Round $g $shadow ($x + 6) ($y + 7) $w $h 8
    Fill-Round $g $surface $x $y $w $h 8
    Stroke-Round $g $border $x $y $w $h 8
    $g.FillRectangle($accentBrush, $x, $y, 7, $h)
    Draw-Text $g $title $palette.Fonts.CardTitle $ink ($x + 24) ($y + 18) ($w - 48) 32
    Draw-Text $g $body $palette.Fonts.CardBody $muted ($x + 24) ($y + 56) ($w - 48) ($h - 66)
  } finally {
    $shadow.Dispose()
    $surface.Dispose()
    $border.Dispose()
    $accentBrush.Dispose()
    $ink.Dispose()
    $muted.Dispose()
  }
}

function Draw-Step($g, $palette, [string]$num, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent) {
  Draw-Card $g $palette $title $body $x $y $w $h $accent
  $badge = [System.Drawing.SolidBrush]::new($accent)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  try {
    $g.FillEllipse($badge, ($x + $w - 48), ($y + 18), 32, 32)
    Draw-Text $g $num $palette.Fonts.Badge $white ($x + $w - 48) ($y + 18) 32 32 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $badge.Dispose()
    $white.Dispose()
  }
}

function Draw-Footer($g, $palette, [string]$text) {
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  try {
    Draw-Text $g $text $palette.Fonts.Small $muted 80 1276 920 36
  } finally {
    $muted.Dispose()
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$outputDir = Join-Path $repoRoot "linkedin-assets-v4"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$regular = New-Family "Segoe UI" "Arial"
$semibold = New-Family "Segoe UI Semibold" "Arial"
$black = New-Family "Segoe UI Black" "Arial"

$palette = @{
  Paper = New-Color "#F7F8FA"
  Surface = New-Color "#FFFFFF"
  Ink = New-Color "#111827"
  Muted = New-Color "#52616F"
  Border = New-Color "#D6DEE8"
  Rule = New-Color "#E5EAF0"
  Grid = New-Color "#DDE6EE" 145
  Shadow = New-Color "#CDD7E2" 120
  White = New-Color "#FFFFFF"
  Teal = New-Color "#047A72"
  Blue = New-Color "#2563EB"
  Gold = New-Color "#B7791F"
  Coral = New-Color "#E85D4F"
  Slate = New-Color "#1F2937"
}

$palette.Fonts = @{
  Eyebrow = New-Font $semibold 22 ([System.Drawing.FontStyle]::Bold)
  Title = New-Font $black 58 ([System.Drawing.FontStyle]::Bold)
  Hero = New-Font $black 74 ([System.Drawing.FontStyle]::Bold)
  Body = New-Font $regular 25
  CardTitle = New-Font $semibold 24 ([System.Drawing.FontStyle]::Bold)
  CardBody = New-Font $regular 19
  Small = New-Font $regular 17
  Pill = New-Font $semibold 17 ([System.Drawing.FontStyle]::Bold)
  Badge = New-Font $semibold 16 ([System.Drawing.FontStyle]::Bold)
  Lane = New-Font $semibold 19 ([System.Drawing.FontStyle]::Bold)
  Event = New-Font $regular 18
}

function Draw-Cover($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Draw-Background $g $palette 1080 1350

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  $teal = [System.Drawing.SolidBrush]::new($palette.Teal)

  try {
    Fill-Round $g $teal 80 72 132 48 24
    Draw-Text $g "RAG + AI" $palette.Fonts.Pill $white 80 72 132 48 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Draw-Text $g "01 / 03" $palette.Fonts.Small $muted 850 82 150 30 ([System.Drawing.StringAlignment]::Far)
    Draw-Text $g "RAG Platform\nfor the Vercel AI SDK era" $palette.Fonts.Hero $ink 80 172 910 218
    Draw-Text $g "A TypeScript-first learning platform for retrieval, grounded generation, and source-aware study workflows." $palette.Fonts.Body $muted 82 424 880 94

    Draw-Pill $g $palette "RAG pipeline" 82 560 168 $palette.Teal $palette.White
    Draw-Pill $g $palette "Vercel AI SDK patterns" 272 560 260 $palette.Blue $palette.White
    Draw-Pill $g $palette "Next.js App Router" 554 560 220 $palette.Gold $palette.White

    $panel = [System.Drawing.SolidBrush]::new($palette.Surface)
    $border = [System.Drawing.Pen]::new($palette.Border, 1.8)
    Fill-Round $g $panel 92 704 896 414 8
    Stroke-Round $g $border 92 704 896 414 8
    $panel.Dispose()
    $border.Dispose()

    Draw-Card $g $palette "Ingest" "PDF, DOCX, TXT" 144 784 220 112 $palette.Teal
    Draw-Card $g $palette "Retrieve" "Lesson vectors" 430 784 220 112 $palette.Blue
    Draw-Card $g $palette "Generate" "Grounded output" 716 784 220 112 $palette.Gold
    Draw-Card $g $palette "AI UX layer" "Vercel AI SDK direction" 430 964 220 112 $palette.Coral

    Draw-Connector $g ([float[]]@(364, 840, 430, 840)) $palette.Teal 5
    Draw-Connector $g ([float[]]@(650, 840, 716, 840)) $palette.Blue 5
    Draw-Connector $g ([float[]]@(826, 896, 826, 932, 540, 932, 540, 964)) $palette.Gold 5

    Draw-Footer $g $palette "Built after LangChain, LangGraph, and Spring AI -> exploring TypeScript-native RAG and Vercel AI SDK patterns."
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $white.Dispose()
    $teal.Dispose()
  }

  Save-Canvas $canvas $path
}

function Draw-Flowchart($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Draw-Background $g $palette 1080 1350
  Draw-Header $g $palette "RAG FLOWCHART" "Retrieval-first architecture" "A clean RAG path: ingest documents, retrieve lesson-scoped context, then generate source-aware learning outputs." "02 / 03"

  $x = 330
  $w = 420
  $h = 94
  $ys = @(370, 506, 642, 782, 970, 1106)

  Draw-Step $g $palette "1" "Ingest sources" "PDF, DOCX, TXT, pasted text" $x $ys[0] $w $h $palette.Teal
  Draw-Step $g $palette "2" "Extract and chunk" "Readable text -> retrieval units" $x $ys[1] $w $h $palette.Blue
  Draw-Step $g $palette "3" "Create embeddings" "OpenAI vector embeddings" $x $ys[2] $w $h $palette.Coral

  Draw-Card $g $palette "PostgreSQL" "Lessons, documents,\nMCQs, generated notes" 92 $ys[3] 370 126 $palette.Blue
  Draw-Card $g $palette "LanceDB" "lesson_chunks\nvector retrieval" 618 $ys[3] 370 126 $palette.Teal

  Draw-Step $g $palette "4" "Retrieve context" "Top chunks scoped by lessonId" $x $ys[4] $w $h $palette.Gold
  Draw-Step $g $palette "5" "AI output layer" "Lessons, quizzes, chat answers" $x $ys[5] $w $h $palette.Coral

  Draw-Connector $g ([float[]]@(540, 464, 540, 506)) $palette.Teal 5
  Draw-Connector $g ([float[]]@(540, 600, 540, 642)) $palette.Blue 5
  Draw-Connector $g ([float[]]@(540, 736, 540, 756, 277, 756, 277, 782)) $palette.Blue 5
  Draw-Connector $g ([float[]]@(540, 736, 540, 756, 803, 756, 803, 782)) $palette.Teal 5
  Draw-Connector $g ([float[]]@(277, 908, 277, 940, 540, 940, 540, 970)) $palette.Blue 5
  Draw-Connector $g ([float[]]@(803, 908, 803, 940, 540, 940, 540, 970)) $palette.Teal 5
  Draw-Connector $g ([float[]]@(540, 1064, 540, 1106)) $palette.Gold 5

  $note = [System.Drawing.SolidBrush]::new($palette.Slate)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  try {
    Fill-Round $g $note 92 1232 896 60 8
    Draw-Text $g "RAG stays central: every lesson, MCQ, and chat answer comes from retrieved context." $palette.Fonts.CardBody $white 126 1248 828 30
  } finally {
    $note.Dispose()
    $white.Dispose()
  }

  Save-Canvas $canvas $path
}

function Draw-Sequence($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Draw-Background $g $palette 1080 1350
  Draw-Header $g $palette "SYSTEM DIAGRAM" "RAG + AI SDK direction" "The product path from authenticated learner action to grounded output, with the AI layer ready for Vercel AI SDK-style UX patterns." "03 / 03"

  $lanes = @(
    @{ Label = "Learner"; X = 112; C = $palette.Slate },
    @{ Label = "Next.js"; X = 306; C = $palette.Blue },
    @{ Label = "RAG APIs"; X = 500; C = $palette.Gold },
    @{ Label = "AI layer"; X = 694; C = $palette.Coral },
    @{ Label = "Data"; X = 888; C = $palette.Teal }
  )

  foreach ($lane in $lanes) {
    $fill = [System.Drawing.SolidBrush]::new($lane.C)
    $white = [System.Drawing.SolidBrush]::new($palette.White)
    $dash = [System.Drawing.Pen]::new($palette.Border, 2)
    $dash.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    try {
      Fill-Round $g $fill ($lane.X - 72) 380 144 44 8
      Draw-Text $g $lane.Label $palette.Fonts.Lane $white ($lane.X - 72) 380 144 44 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
      $g.DrawLine($dash, $lane.X, 438, $lane.X, 1128)
    } finally {
      $fill.Dispose()
      $white.Dispose()
      $dash.Dispose()
    }
  }

  $events = @(
    @{ A = 0; B = 1; Y = 492; L = "Open lesson"; C = $palette.Slate },
    @{ A = 1; B = 2; Y = 584; L = "Validate + route"; C = $palette.Blue },
    @{ A = 0; B = 1; Y = 676; L = "Upload documents"; C = $palette.Slate },
    @{ A = 1; B = 2; Y = 768; L = "Ingest request"; C = $palette.Blue },
    @{ A = 2; B = 3; Y = 860; L = "Embeddings / generation"; C = $palette.Coral },
    @{ A = 2; B = 4; Y = 952; L = "Metadata + vectors"; C = $palette.Teal },
    @{ A = 0; B = 1; Y = 1044; L = "Ask / generate"; C = $palette.Slate },
    @{ A = 2; B = 4; Y = 1136; L = "Retrieve context -> answer"; C = $palette.Gold }
  )

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  foreach ($event in $events) {
    $x1 = $lanes[$event.A].X
    $x2 = $lanes[$event.B].X
    $labelW = [Math]::Max([Math]::Abs($x2 - $x1), 230)
    $labelX = [Math]::Min($x1, $x2) - (($labelW - [Math]::Abs($x2 - $x1)) / 2)
    Draw-Text $g $event.L $palette.Fonts.Event $ink $labelX ($event.Y - 34) $labelW 28 ([System.Drawing.StringAlignment]::Center)
    Draw-Connector $g ([float[]]@($x1, $event.Y, $x2, $event.Y)) $event.C 4
  }
  $ink.Dispose()

  Draw-Card $g $palette "AI layer direction" "OpenAI SDK today. Vercel AI SDK patterns for TypeScript AI UX." 110 1196 860 104 $palette.Blue

  Save-Canvas $canvas $path
}

function Draw-Thumbnail($path, $palette) {
  $canvas = New-Canvas 1600 900 $palette.Paper
  $g = $canvas.Graphics
  Draw-Background $g $palette 1600 900

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  $teal = [System.Drawing.SolidBrush]::new($palette.Teal)
  try {
    Fill-Round $g $teal 92 76 148 52 26
    Draw-Text $g "RAG + AI" $palette.Fonts.Pill $white 92 76 148 52 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Draw-Text $g "RAG Platform\nfor Vercel AI SDK" $palette.Fonts.Hero $ink 92 174 820 178
    Draw-Text $g "TypeScript-first retrieval, grounded generation, and learning workflows." $palette.Fonts.Body $muted 98 394 820 70

    Draw-Pill $g $palette "RAG pipeline" 98 508 164 $palette.Teal $palette.White
    Draw-Pill $g $palette "Vercel AI SDK patterns" 286 508 264 $palette.Blue $palette.White
    Draw-Pill $g $palette "Source-grounded UX" 574 508 244 $palette.Gold $palette.White

    Draw-Card $g $palette "Sources" "PDF / DOCX / TXT" 990 116 240 112 $palette.Teal
    Draw-Card $g $palette "Retrieval" "LanceDB vectors" 1280 116 240 112 $palette.Blue
    Draw-Card $g $palette "AI layer" "OpenAI SDK now" 990 330 240 112 $palette.Coral
    Draw-Card $g $palette "SDK direction" "Vercel AI SDK" 1280 330 240 112 $palette.Gold
    Draw-Card $g $palette "Outputs" "Lessons, MCQs, chat" 1135 590 260 126 $palette.Teal

    Draw-Connector $g ([float[]]@(1230, 172, 1280, 172)) $palette.Teal 5
    Draw-Connector $g ([float[]]@(1110, 228, 1110, 330)) $palette.Coral 5
    Draw-Connector $g ([float[]]@(1400, 228, 1400, 330)) $palette.Blue 5
    Draw-Connector $g ([float[]]@(1110, 442, 1110, 510, 1265, 510, 1265, 590)) $palette.Coral 5
    Draw-Connector $g ([float[]]@(1400, 442, 1400, 510, 1265, 510, 1265, 590)) $palette.Gold 5

    Draw-Text $g "LangChain / LangGraph / Spring AI veteran exploring the TypeScript-native AI stack." $palette.Fonts.Small $muted 98 796 900 36
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $white.Dispose()
    $teal.Dispose()
  }

  Save-Canvas $canvas $path
}

$cover = Join-Path $outputDir "01-rag-vercel-ai-sdk-cover.png"
$flowchart = Join-Path $outputDir "02-rag-pipeline-flowchart.png"
$sequence = Join-Path $outputDir "03-rag-ai-sdk-system-diagram.png"
$thumbnail = Join-Path $outputDir "linkedin-thumbnail.png"
$captionPath = Join-Path $outputDir "linkedin-caption.txt"
$readmePath = Join-Path $outputDir "README.md"

Draw-Cover $cover $palette
Draw-Flowchart $flowchart $palette
Draw-Sequence $sequence $palette
Draw-Thumbnail $thumbnail $palette

$caption = @'
I have built RAG systems with LangChain, LangGraph, and Spring AI, so I wanted to spend time with the TypeScript-native AI ecosystem more intentionally.

This project is a small RAG learning platform focused on retrieval-first learning workflows:

- Next.js App Router for the product and API layer
- OpenAI SDK for embeddings and generation in the current implementation
- Prisma + PostgreSQL for lessons, documents, generated lessons, and MCQs
- LanceDB for lesson-scoped vector retrieval
- Vercel AI SDK patterns as the direction I wanted to explore for polished TypeScript AI UX and orchestration

The core idea is simple:

Ingest documents.
Retrieve lesson-scoped context.
Generate grounded lessons, quizzes, and chat answers with source references.

What I liked most was seeing how much of a good RAG product comes down to engineering discipline: clean retrieval boundaries, reliable data flow, traceable sources, and a user experience that makes the model output actually useful.

#RAG #VercelAI #TypeScript #LLM #NextJS #OpenAI #Prisma #PostgreSQL #LanceDB #GenAI #SoftwareEngineering
'@

$readme = @'
# LinkedIn Assets V4

Elegant LinkedIn-ready PNG assets emphasizing RAG and the Vercel AI SDK ecosystem.

Files:
- `01-rag-vercel-ai-sdk-cover.png`
- `02-rag-pipeline-flowchart.png`
- `03-rag-ai-sdk-system-diagram.png`
- `linkedin-thumbnail.png`
- `linkedin-caption.txt`

Generated from:
- `scripts/generate-linkedin-assets-v4.ps1`
'@

Set-Content -Path $captionPath -Value $caption -Encoding UTF8
Set-Content -Path $readmePath -Value $readme -Encoding UTF8

Write-Host "Created v4 LinkedIn assets in: $outputDir"
