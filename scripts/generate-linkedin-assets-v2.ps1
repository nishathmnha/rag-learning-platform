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

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()

  return $path
}

function Fill-Round($graphics, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 16) {
  $path = New-RoundedPath $x $y $w $h $r
  try {
    $graphics.FillPath($brush, $path)
  } finally {
    $path.Dispose()
  }
}

function Stroke-Round($graphics, $pen, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 16) {
  $path = New-RoundedPath $x $y $w $h $r
  try {
    $graphics.DrawPath($pen, $path)
  } finally {
    $path.Dispose()
  }
}

function Text(
  $graphics,
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
  try {
    $graphics.DrawString($content, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $format)
  } finally {
    $format.Dispose()
  }
}

function Line($graphics, [float]$x1, [float]$y1, [float]$x2, [float]$y2, $color, [float]$width = 4, [bool]$arrow = $false) {
  $pen = [System.Drawing.Pen]::new($color, $width)
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

  if ($arrow) {
    $cap = [System.Drawing.Drawing2D.AdjustableArrowCap]::new(7, 9)
    $pen.CustomEndCap = $cap
  }

  try {
    $graphics.DrawLine($pen, $x1, $y1, $x2, $y2)
  } finally {
    if ($arrow) {
      $cap.Dispose()
    }
    $pen.Dispose()
  }
}

function DotGrid($graphics, $palette, [int]$width, [int]$height) {
  $brush = [System.Drawing.SolidBrush]::new($palette.Grid)
  try {
    for ($x = 36; $x -lt $width; $x += 54) {
      for ($y = 36; $y -lt $height; $y += 54) {
        $graphics.FillEllipse($brush, $x, $y, 2, 2)
      }
    }
  } finally {
    $brush.Dispose()
  }
}

function Draw-Header($graphics, $palette, [string]$kicker, [string]$title, [string]$subtitle, [string]$slideNo) {
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $accent = [System.Drawing.SolidBrush]::new($palette.Teal)
  try {
    Text $graphics $kicker $palette.Fonts.Kicker $accent 72 64 520 30
    Text $graphics $slideNo $palette.Fonts.Small $muted 848 64 160 30 ([System.Drawing.StringAlignment]::Far)
    Text $graphics $title $palette.Fonts.Title $ink 72 108 900 128
    Text $graphics $subtitle $palette.Fonts.Body $muted 72 248 860 78
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $accent.Dispose()
  }
}

function Draw-Pill($graphics, $palette, [string]$text, [float]$x, [float]$y, [float]$w, $fill, $textColor = $null) {
  if ($null -eq $textColor) {
    $textColor = $palette.Ink
  }

  $fillBrush = [System.Drawing.SolidBrush]::new($fill)
  $textBrush = [System.Drawing.SolidBrush]::new($textColor)
  try {
    Fill-Round $graphics $fillBrush $x $y $w 44 22
    Text $graphics $text $palette.Fonts.Pill $textBrush $x $y $w 44 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $fillBrush.Dispose()
    $textBrush.Dispose()
  }
}

function Draw-Card($graphics, $palette, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent) {
  $shadow = [System.Drawing.SolidBrush]::new($palette.Shadow)
  $fill = [System.Drawing.SolidBrush]::new($palette.Surface)
  $border = [System.Drawing.Pen]::new($palette.Border, 2)
  $accentBrush = [System.Drawing.SolidBrush]::new($accent)
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)

  try {
    Fill-Round $graphics $shadow ($x + 8) ($y + 10) $w $h 18
    Fill-Round $graphics $fill $x $y $w $h 18
    Stroke-Round $graphics $border $x $y $w $h 18
    Fill-Round $graphics $accentBrush $x $y 10 $h 5
    Text $graphics $title $palette.Fonts.CardTitle $ink ($x + 28) ($y + 20) ($w - 52) 42
    Text $graphics $body $palette.Fonts.CardBody $muted ($x + 28) ($y + 68) ($w - 52) ($h - 82)
  } finally {
    $shadow.Dispose()
    $fill.Dispose()
    $border.Dispose()
    $accentBrush.Dispose()
    $ink.Dispose()
    $muted.Dispose()
  }
}

function Draw-Step($graphics, $palette, [string]$number, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent) {
  Draw-Card $graphics $palette $title $body $x $y $w $h $accent
  $badge = [System.Drawing.SolidBrush]::new($accent)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  try {
    $graphics.FillEllipse($badge, ($x + $w - 58), ($y + 18), 36, 36)
    Text $graphics $number $palette.Fonts.StepNo $white ($x + $w - 58) ($y + 18) 36 36 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $badge.Dispose()
    $white.Dispose()
  }
}

function Draw-Footer($graphics, $palette, [string]$text) {
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  try {
    Text $graphics $text $palette.Fonts.Small $muted 72 1276 936 38
  } finally {
    $muted.Dispose()
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$outputDir = Join-Path $repoRoot "linkedin-assets-v2"

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$regular = New-Family "Segoe UI" "Arial"
$semibold = New-Family "Segoe UI Semibold" "Arial"
$bold = New-Family "Segoe UI Black" "Arial"

$palette = @{
  Paper = New-Color "#F7F9F5"
  Surface = New-Color "#FFFFFF"
  Ink = New-Color "#101820"
  Muted = New-Color "#52606D"
  Border = New-Color "#D9E2EC"
  Shadow = New-Color "#DDE7D8" 125
  Grid = New-Color "#CFE1D7" 150
  White = New-Color "#FFFFFF"
  Teal = New-Color "#0F766E"
  Blue = New-Color "#2563EB"
  Coral = New-Color "#F9735B"
  Amber = New-Color "#F5B942"
  Lime = New-Color "#A3E635"
  InkSoft = New-Color "#1F2937"
}

$palette.Fonts = @{
  Kicker = New-Font $semibold 22 ([System.Drawing.FontStyle]::Bold)
  Title = New-Font $bold 56 ([System.Drawing.FontStyle]::Bold)
  Hero = New-Font $bold 72 ([System.Drawing.FontStyle]::Bold)
  Body = New-Font $regular 25
  CardTitle = New-Font $semibold 25 ([System.Drawing.FontStyle]::Bold)
  CardBody = New-Font $regular 20
  Small = New-Font $regular 18
  Pill = New-Font $semibold 20 ([System.Drawing.FontStyle]::Bold)
  StepNo = New-Font $semibold 18 ([System.Drawing.FontStyle]::Bold)
  Lane = New-Font $semibold 21 ([System.Drawing.FontStyle]::Bold)
  Sequence = New-Font $regular 22
}

function Draw-Cover($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  DotGrid $g $palette 1080 1350

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $teal = [System.Drawing.SolidBrush]::new($palette.Teal)
  $coral = [System.Drawing.SolidBrush]::new($palette.Coral)
  $amber = [System.Drawing.SolidBrush]::new($palette.Amber)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  try {
    Fill-Round $g $teal 72 72 92 54 27
    Text $g "TS" $palette.Fonts.Pill $white 72 72 92 54 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Text $g "01 / 03" $palette.Fonts.Small $muted 848 84 160 30 ([System.Drawing.StringAlignment]::Far)
    Text $g "TypeScript RAG\nLearning Platform" $palette.Fonts.Hero $ink 72 174 900 220
    Text $g "A learning-first RAG app built with Next.js, Prisma, OpenAI, and LanceDB." $palette.Fonts.Body $muted 76 424 826 88

    Draw-Pill $g $palette "PDF / DOCX / TXT" 76 548 208 $palette.Lime $palette.Ink
    Draw-Pill $g $palette "Grounded outputs" 306 548 228 $palette.Amber $palette.Ink
    Draw-Pill $g $palette "Shared retrieval" 556 548 218 $palette.Coral $palette.White

    Fill-Round $g $white 92 704 896 450 28
    Stroke-Round $g ([System.Drawing.Pen]::new($palette.Border, 2)) 92 704 896 450 28

    Draw-Card $g $palette "Ingest" "Files or pasted text" 136 768 238 126 $palette.Teal
    Draw-Card $g $palette "Index" "Chunks and vectors" 420 768 238 126 $palette.Blue
    Draw-Card $g $palette "Retrieve" "Top lesson chunks" 704 768 238 126 $palette.Amber
    Draw-Card $g $palette "Generate" "Lesson, quiz, chat" 420 960 238 126 $palette.Coral

    Line $g 374 831 420 831 $palette.Teal 5 $true
    Line $g 658 831 704 831 $palette.Blue 5 $true
    Line $g 823 894 538 960 $palette.Amber 5 $true

    Fill-Round $g $coral 72 1218 286 54 27
    Text $g "LinkedIn carousel pack" $palette.Fonts.Pill $white 72 1218 286 54 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Text $g "LangChain / LangGraph / Spring AI background -> exploring the TypeScript LLM stack" $palette.Fonts.Small $muted 384 1222 584 48
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $teal.Dispose()
    $coral.Dispose()
    $amber.Dispose()
    $white.Dispose()
  }

  Save-Canvas $canvas $path
}

function Draw-Flow($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  DotGrid $g $palette 1080 1350
  Draw-Header $g $palette "RAG FLOWCHART" "From document to answer" "The retrieval pipeline is lesson-scoped, then reused across lesson notes, MCQs, and chat." "02 / 03"

  $leftX = 86
  $rightX = 570
  $w = 424
  $h = 132
  $rows = @(342, 526, 710, 894)
  $steps = @(
    @{ N = "1"; T = "Upload sources"; B = "PDF, DOCX, TXT, or pasted text"; X = $leftX; Y = $rows[0]; C = $palette.Teal },
    @{ N = "2"; T = "Extract text"; B = "Normalize readable content"; X = $rightX; Y = $rows[0]; C = $palette.Blue },
    @{ N = "3"; T = "Chunk content"; B = "Split into retrieval units"; X = $rightX; Y = $rows[1]; C = $palette.Amber },
    @{ N = "4"; T = "Embed chunks"; B = "OpenAI vector embeddings"; X = $leftX; Y = $rows[1]; C = $palette.Coral },
    @{ N = "5"; T = "Persist metadata"; B = "Prisma + PostgreSQL"; X = $leftX; Y = $rows[2]; C = $palette.Blue },
    @{ N = "6"; T = "Index vectors"; B = "LanceDB lesson_chunks"; X = $rightX; Y = $rows[2]; C = $palette.Teal },
    @{ N = "7"; T = "Retrieve context"; B = "Top relevant lesson chunks"; X = $rightX; Y = $rows[3]; C = $palette.Amber },
    @{ N = "8"; T = "Generate output"; B = "Lessons, MCQs, or chat with sources"; X = $leftX; Y = $rows[3]; C = $palette.Coral }
  )

  foreach ($step in $steps) {
    Draw-Step $g $palette $step.N $step.T $step.B $step.X $step.Y $w $h $step.C
  }

  Line $g ($leftX + $w) ($rows[0] + 66) $rightX ($rows[0] + 66) $palette.Teal 5 $true
  Line $g ($rightX + 212) ($rows[0] + $h) ($rightX + 212) $rows[1] $palette.Blue 5 $true
  Line $g $rightX ($rows[1] + 66) ($leftX + $w) ($rows[1] + 66) $palette.Amber 5 $true
  Line $g ($leftX + 212) ($rows[1] + $h) ($leftX + 212) $rows[2] $palette.Coral 5 $true
  Line $g ($leftX + $w) ($rows[2] + 66) $rightX ($rows[2] + 66) $palette.Blue 5 $true
  Line $g ($rightX + 212) ($rows[2] + $h) ($rightX + 212) $rows[3] $palette.Teal 5 $true
  Line $g $rightX ($rows[3] + 66) ($leftX + $w) ($rows[3] + 66) $palette.Amber 5 $true

  $fill = [System.Drawing.SolidBrush]::new($palette.Ink)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  try {
    Fill-Round $g $fill 100 1124 880 86 18
    Text $g "One retrieval core powers lessons, MCQs, and grounded chat." $palette.Fonts.CardBody $white 136 1144 808 48
  } finally {
    $fill.Dispose()
    $white.Dispose()
  }

  Draw-Footer $g $palette "Stack: Next.js App Router, Auth.js, Prisma, PostgreSQL, OpenAI, LanceDB"
  Save-Canvas $canvas $path
}

function Draw-Sequence($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  DotGrid $g $palette 1080 1350
  Draw-Header $g $palette "SEQUENCE DIAGRAM" "System sequence" "A compact view from login to ingestion to grounded generation." "03 / 03"

  $lanes = @(
    @{ Name = "User"; X = 92; C = $palette.Ink },
    @{ Name = "Next.js"; X = 270; C = $palette.Blue },
    @{ Name = "API"; X = 448; C = $palette.Amber },
    @{ Name = "OpenAI"; X = 626; C = $palette.Coral },
    @{ Name = "Storage"; X = 804; C = $palette.Teal }
  )

  foreach ($lane in $lanes) {
    $brush = [System.Drawing.SolidBrush]::new($lane.C)
    $white = [System.Drawing.SolidBrush]::new($palette.White)
    $dash = [System.Drawing.Pen]::new($palette.Border, 2)
    $dash.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    try {
      Fill-Round $g $brush $lane.X 342 144 52 18
      Text $g $lane.Name $palette.Fonts.Lane $white $lane.X 342 144 52 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
      $g.DrawLine($dash, ($lane.X + 72), 394, ($lane.X + 72), 1090)
    } finally {
      $brush.Dispose()
      $white.Dispose()
      $dash.Dispose()
    }
  }

  $events = @(
    @{ F = 0; T = 1; Y = 444; L = "1. Open dashboard and lesson workspace"; C = $palette.Ink },
    @{ F = 1; T = 2; Y = 520; L = "2. Validate session and lesson ownership"; C = $palette.Blue },
    @{ F = 0; T = 1; Y = 610; L = "3. Upload PDF / DOCX / TXT or pasted text"; C = $palette.Ink },
    @{ F = 1; T = 2; Y = 686; L = "4. POST /api/lessons/[id]/documents"; C = $palette.Blue },
    @{ F = 2; T = 3; Y = 762; L = "5. Create chunk embeddings"; C = $palette.Amber },
    @{ F = 2; T = 4; Y = 838; L = "6. Save metadata and index vectors"; C = $palette.Teal },
    @{ F = 0; T = 1; Y = 928; L = "7. Generate lesson, MCQ, or chat answer"; C = $palette.Ink },
    @{ F = 2; T = 4; Y = 1004; L = "8. Retrieve top lesson chunks"; C = $palette.Amber },
    @{ F = 2; T = 3; Y = 1080; L = "9. Generate grounded response"; C = $palette.Coral }
  )

  foreach ($event in $events) {
    $from = $lanes[$event.F].X + 72
    $to = $lanes[$event.T].X + 72
    Line $g $from $event.Y $to $event.Y $event.C 4 $true

    $labelW = [Math]::Min(388, [Math]::Abs($to - $from) + 160)
    $labelX = [Math]::Min($from, $to) + ([Math]::Abs($to - $from) / 2) - ($labelW / 2)
    $labelY = $event.Y - 34
    $pill = [System.Drawing.SolidBrush]::new($palette.Surface)
    $border = [System.Drawing.Pen]::new($palette.Border, 1)
    $text = [System.Drawing.SolidBrush]::new($palette.Ink)
    try {
      Fill-Round $g $pill $labelX $labelY $labelW 42 21
      Stroke-Round $g $border $labelX $labelY $labelW 42 21
      Text $g $event.L $palette.Fonts.Small $text $labelX $labelY $labelW 42 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    } finally {
      $pill.Dispose()
      $border.Dispose()
      $text.Dispose()
    }
  }

  Draw-Card $g $palette "Important design choice" "PostgreSQL stores app state. LanceDB handles vectors. Both are keyed by lessonId." 108 1140 864 128 $palette.Teal
  Draw-Footer $g $palette "This is the path used by ingestion, lesson generation, MCQ generation, and chat."

  Save-Canvas $canvas $path
}

function Draw-Thumbnail($path, $palette) {
  $canvas = New-Canvas 1600 900 $palette.Paper
  $g = $canvas.Graphics
  DotGrid $g $palette 1600 900

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  $teal = [System.Drawing.SolidBrush]::new($palette.Teal)
  try {
    Fill-Round $g $teal 86 82 120 58 29
    Text $g "TS RAG" $palette.Fonts.Pill $white 86 82 120 58 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Text $g "TypeScript RAG\nLearning Platform" $palette.Fonts.Hero $ink 86 172 760 188
    Text $g "A clean RAG product experiment with Next.js, Prisma, OpenAI, and LanceDB." $palette.Fonts.Body $muted 92 384 700 70

    Draw-Pill $g $palette "Document ingestion" 92 498 244 $palette.Lime $palette.Ink
    Draw-Pill $g $palette "Vector search" 358 498 190 $palette.Amber $palette.Ink
    Draw-Pill $g $palette "Grounded outputs" 570 498 228 $palette.Coral $palette.White

    Draw-Card $g $palette "Sources" "PDF / DOCX / TXT" 940 130 250 132 $palette.Teal
    Draw-Card $g $palette "Embeddings" "OpenAI vectors" 1260 130 250 132 $palette.Coral
    Draw-Card $g $palette "Metadata" "Prisma + Postgres" 940 356 250 132 $palette.Blue
    Draw-Card $g $palette "Vector store" "LanceDB chunks" 1260 356 250 132 $palette.Teal
    Draw-Card $g $palette "Outputs" "Lessons, MCQs, chat" 1100 602 286 150 $palette.Amber

    Line $g 1190 196 1260 196 $palette.Teal 5 $true
    Line $g 1065 262 1065 356 $palette.Blue 5 $true
    Line $g 1385 262 1385 356 $palette.Coral 5 $true
    Line $g 1065 488 1180 602 $palette.Blue 5 $true
    Line $g 1385 488 1276 602 $palette.Teal 5 $true

    Text $g "After LangChain, LangGraph, and Spring AI - exploring the TypeScript LLM path." $palette.Fonts.Small $muted 92 808 860 38
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $white.Dispose()
    $teal.Dispose()
  }

  Save-Canvas $canvas $path
}

$coverPath = Join-Path $outputDir "01-cover-typescript-rag-platform.png"
$flowPath = Join-Path $outputDir "02-rag-system-flowchart.png"
$sequencePath = Join-Path $outputDir "03-system-sequence-diagram.png"
$thumbnailPath = Join-Path $outputDir "linkedin-thumbnail.png"
$captionPath = Join-Path $outputDir "linkedin-caption.txt"
$readmePath = Join-Path $outputDir "README.md"

Draw-Cover $coverPath $palette
Draw-Flow $flowPath $palette
Draw-Sequence $sequencePath $palette
Draw-Thumbnail $thumbnailPath $palette

$caption = @'
I have built RAG systems with LangChain, LangGraph, and Spring AI, so this time I wanted to explore the TypeScript LLM path more directly.

I built a small RAG learning platform with:

- Next.js App Router for the product and API layer
- Prisma + PostgreSQL for users, lessons, documents, generated lessons, and MCQs
- LanceDB for lesson-scoped vector retrieval
- OpenAI embeddings and generation APIs for ingestion, lesson generation, quiz generation, and grounded chat

The part I enjoyed most was keeping the retrieval core simple and reusable.

One document pipeline.
One lesson-scoped vector store.
Three user-facing outputs: lessons, quizzes, and chat answers with sources.

For me, this was a useful reminder that good RAG is mostly disciplined product engineering: clean data flow, clear retrieval boundaries, observable sources, and a UI that makes the AI output useful.

#TypeScript #RAG #LLM #NextJS #OpenAI #Prisma #PostgreSQL #LanceDB #GenAI #SoftwareEngineering
'@

$readme = @'
# LinkedIn Assets V2

Improved LinkedIn-ready PNG assets for the TypeScript RAG Learning Platform.

Files:
- `01-cover-typescript-rag-platform.png`
- `02-rag-system-flowchart.png`
- `03-system-sequence-diagram.png`
- `linkedin-thumbnail.png`
- `linkedin-caption.txt`

Generated from:
- `scripts/generate-linkedin-assets-v2.ps1`
'@

Set-Content -Path $captionPath -Value $caption -Encoding UTF8
Set-Content -Path $readmePath -Value $readme -Encoding UTF8

Write-Host "Created v2 LinkedIn assets in: $outputDir"
