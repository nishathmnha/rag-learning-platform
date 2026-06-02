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

function New-RoundPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 6) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function Fill-Round($graphics, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 6) {
  $path = New-RoundPath $x $y $w $h $r
  try {
    $graphics.FillPath($brush, $path)
  } finally {
    $path.Dispose()
  }
}

function Stroke-Round($graphics, $pen, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 6) {
  $path = New-RoundPath $x $y $w $h $r
  try {
    $graphics.DrawPath($pen, $path)
  } finally {
    $path.Dispose()
  }
}

function Draw-Text(
  $graphics,
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
    $graphics.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $format)
  } finally {
    $format.Dispose()
  }
}

function Draw-Line($graphics, [float]$x1, [float]$y1, [float]$x2, [float]$y2, $color, [float]$width = 3, [bool]$arrow = $false) {
  $pen = [System.Drawing.Pen]::new($color, $width)
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

  if ($arrow) {
    $cap = [System.Drawing.Drawing2D.AdjustableArrowCap]::new(7, 8)
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

function Draw-Connector($graphics, [float[]]$points, $color, [float]$width = 3) {
  for ($i = 0; $i -lt ($points.Length / 2) - 2; $i += 1) {
    $p = $i * 2
    Draw-Line $graphics $points[$p] $points[$p + 1] $points[$p + 2] $points[$p + 3] $color $width $false
  }

  $last = $points.Length - 4
  Draw-Line $graphics $points[$last] $points[$last + 1] $points[$last + 2] $points[$last + 3] $color $width $true
}

function Draw-Grid($graphics, $palette, [int]$width, [int]$height) {
  $line = [System.Drawing.Pen]::new($palette.Grid, 1)
  try {
    for ($x = 80; $x -le $width - 80; $x += 120) {
      $graphics.DrawLine($line, $x, 80, $x, $height - 80)
    }

    for ($y = 120; $y -le $height - 120; $y += 120) {
      $graphics.DrawLine($line, 80, $y, $width - 80, $y)
    }
  } finally {
    $line.Dispose()
  }
}

function Draw-Header($graphics, $palette, [string]$label, [string]$title, [string]$subtitle, [string]$page) {
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $accent = [System.Drawing.SolidBrush]::new($palette.Accent)
  try {
    Draw-Text $graphics $label $palette.Fonts.Label $accent 80 74 560 28
    Draw-Text $graphics $page $palette.Fonts.Small $muted 850 74 150 28 ([System.Drawing.StringAlignment]::Far)
    Draw-Text $graphics $title $palette.Fonts.Title $ink 80 126 910 126
    Draw-Text $graphics $subtitle $palette.Fonts.Body $muted 82 268 880 82
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
    Fill-Round $graphics $fillBrush $x $y $w 38 19
    Draw-Text $graphics $text $palette.Fonts.Pill $textBrush $x $y $w 38 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $fillBrush.Dispose()
    $textBrush.Dispose()
  }
}

function Draw-Card($graphics, $palette, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent = $null) {
  if ($null -eq $accent) {
    $accent = $palette.Accent
  }

  $surface = [System.Drawing.SolidBrush]::new($palette.Surface)
  $border = [System.Drawing.Pen]::new($palette.Border, 1.4)
  $accentPen = [System.Drawing.Pen]::new($accent, 3)
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)

  try {
    Fill-Round $graphics $surface $x $y $w $h 6
    Stroke-Round $graphics $border $x $y $w $h 6
    $graphics.DrawLine($accentPen, $x, $y, $x, $y + $h)
    Draw-Text $graphics $title $palette.Fonts.CardTitle $ink ($x + 22) ($y + 18) ($w - 42) 32
    Draw-Text $graphics $body $palette.Fonts.CardBody $muted ($x + 22) ($y + 56) ($w - 42) ($h - 64)
  } finally {
    $surface.Dispose()
    $border.Dispose()
    $accentPen.Dispose()
    $ink.Dispose()
    $muted.Dispose()
  }
}

function Draw-Step($graphics, $palette, [string]$num, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent = $null) {
  if ($null -eq $accent) {
    $accent = $palette.Accent
  }

  Draw-Card $graphics $palette $title $body $x $y $w $h $accent

  $badge = [System.Drawing.SolidBrush]::new($palette.Surface)
  $border = [System.Drawing.Pen]::new($accent, 1.8)
  $text = [System.Drawing.SolidBrush]::new($accent)
  try {
    $graphics.FillEllipse($badge, ($x + $w - 46), ($y + 18), 30, 30)
    $graphics.DrawEllipse($border, ($x + $w - 46), ($y + 18), 30, 30)
    Draw-Text $graphics $num $palette.Fonts.Badge $text ($x + $w - 46) ($y + 18) 30 30 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $badge.Dispose()
    $border.Dispose()
    $text.Dispose()
  }
}

function Draw-Footer($graphics, $palette, [string]$text) {
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $rule = [System.Drawing.Pen]::new($palette.Border, 1)
  try {
    $graphics.DrawLine($rule, 80, 1248, 1000, 1248)
    Draw-Text $graphics $text $palette.Fonts.Small $muted 80 1272 920 34
  } finally {
    $muted.Dispose()
    $rule.Dispose()
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$outputDir = Join-Path $repoRoot "linkedin-assets-v5"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$regular = New-Family "Segoe UI" "Arial"
$semibold = New-Family "Segoe UI Semibold" "Arial"
$black = New-Family "Segoe UI Black" "Arial"

$palette = @{
  Paper = New-Color "#FBFAF7"
  Surface = New-Color "#FFFFFF"
  Ink = New-Color "#151515"
  Muted = New-Color "#5B6470"
  Border = New-Color "#D9DDD8"
  Grid = New-Color "#ECEBE6" 150
  Accent = New-Color "#0E6F68"
  Secondary = New-Color "#2B4E7D"
  Warm = New-Color "#986B2D"
  Critical = New-Color "#9A3D32"
  Soft = New-Color "#F1F4F1"
  White = New-Color "#FFFFFF"
}

$palette.Fonts = @{
  Label = New-Font $semibold 20 ([System.Drawing.FontStyle]::Bold)
  Title = New-Font $black 58 ([System.Drawing.FontStyle]::Bold)
  Hero = New-Font $black 74 ([System.Drawing.FontStyle]::Bold)
  Body = New-Font $regular 25
  CardTitle = New-Font $semibold 23 ([System.Drawing.FontStyle]::Bold)
  CardBody = New-Font $regular 18
  Small = New-Font $regular 16
  Pill = New-Font $semibold 16 ([System.Drawing.FontStyle]::Bold)
  Badge = New-Font $semibold 15 ([System.Drawing.FontStyle]::Bold)
  Event = New-Font $regular 17
}

function Draw-Cover($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Draw-Grid $g $palette 1080 1350

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $accent = [System.Drawing.SolidBrush]::new($palette.Accent)
  $white = [System.Drawing.SolidBrush]::new($palette.White)

  try {
    Fill-Round $g $accent 80 76 108 38 19
    Draw-Text $g "RAG" $palette.Fonts.Pill $white 80 76 108 38 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Draw-Text $g "01 / 04" $palette.Fonts.Small $muted 850 80 150 28 ([System.Drawing.StringAlignment]::Far)
    Draw-Text $g "RAG Learning\nPlatform" $palette.Fonts.Hero $ink 80 188 900 220
    Draw-Text $g "A minimalist TypeScript learning system built around document ingestion, lesson-scoped retrieval, and grounded AI outputs." $palette.Fonts.Body $muted 82 430 860 96

    Draw-Pill $g $palette "Next.js App Router" 82 570 198 $palette.Soft
    Draw-Pill $g $palette "OpenAI SDK" 302 570 136 $palette.Soft
    Draw-Pill $g $palette "Prisma + PostgreSQL" 460 570 220 $palette.Soft
    Draw-Pill $g $palette "LanceDB" 702 570 110 $palette.Soft

    $panelBrush = [System.Drawing.SolidBrush]::new($palette.Surface)
    $panelPen = [System.Drawing.Pen]::new($palette.Border, 1.4)
    Fill-Round $g $panelBrush 92 724 896 366 6
    Stroke-Round $g $panelPen 92 724 896 366 6
    $panelBrush.Dispose()
    $panelPen.Dispose()

    Draw-Card $g $palette "Ingest" "Files or text" 150 806 210 104 $palette.Accent
    Draw-Card $g $palette "Retrieve" "Top lesson chunks" 435 806 210 104 $palette.Secondary
    Draw-Card $g $palette "Generate" "Learning outputs" 720 806 210 104 $palette.Warm
    Draw-Card $g $palette "Vercel AI SDK" "Exploration direction" 435 972 210 104 $palette.Critical

    Draw-Connector $g ([float[]]@(360, 858, 435, 858)) $palette.Accent 4
    Draw-Connector $g ([float[]]@(645, 858, 720, 858)) $palette.Secondary 4
    Draw-Connector $g ([float[]]@(825, 910, 825, 940, 540, 940, 540, 972)) $palette.Warm 4

    Draw-Footer $g $palette "Current implementation uses OpenAI SDK directly. Vercel AI SDK is the TypeScript AI workflow direction being explored."
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $accent.Dispose()
    $white.Dispose()
  }

  Save-Canvas $canvas $path
}

function Draw-IngestionWorkflow($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Draw-Grid $g $palette 1080 1350
  Draw-Header $g $palette "WORKFLOW 01" "Document ingestion" "What happens when a learner uploads PDF, DOCX, TXT, or pasted text into a lesson workspace." "02 / 04"

  $x = 260
  $w = 560
  $h = 86
  $ys = @(390, 518, 646, 774, 902, 1030)

  Draw-Step $g $palette "1" "Validate lesson ownership" "getServerSession + lesson userId check" $x $ys[0] $w $h $palette.Secondary
  Draw-Step $g $palette "2" "Extract readable text" "extractTextFromFile: pdf-parse, mammoth, UTF-8 text" $x $ys[1] $w $h $palette.Accent
  Draw-Step $g $palette "3" "Chunk source content" "chunkText creates retrieval-ready text segments" $x $ys[2] $w $h $palette.Accent
  Draw-Step $g $palette "4" "Create embeddings" "createEmbeddings calls the OpenAI embeddings API" $x $ys[3] $w $h $palette.Critical
  Draw-Step $g $palette "5" "Persist relational data" "Prisma transaction stores document and chunk rows" $x $ys[4] $w $h $palette.Secondary
  Draw-Step $g $palette "6" "Index vectors" "upsertLessonChunksToLanceDb writes lesson_chunks" $x $ys[5] $w $h $palette.Warm

  for ($i = 0; $i -lt 5; $i += 1) {
    Draw-Connector $g ([float[]]@(540, ($ys[$i] + $h), 540, $ys[$i + 1])) $palette.Muted 3
  }

  $noteBrush = [System.Drawing.SolidBrush]::new($palette.Soft)
  $notePen = [System.Drawing.Pen]::new($palette.Border, 1.2)
  $noteText = [System.Drawing.SolidBrush]::new($palette.Ink)
  try {
    Fill-Round $g $noteBrush 150 1168 780 54 6
    Stroke-Round $g $notePen 150 1168 780 54 6
    Draw-Text $g "Failure behavior: if LanceDB indexing fails, the saved document is deleted to avoid stale metadata." $palette.Fonts.Small $noteText 176 1184 728 22
  } finally {
    $noteBrush.Dispose()
    $notePen.Dispose()
    $noteText.Dispose()
  }

  Draw-Footer $g $palette "Route: app/api/lessons/[id]/documents. Core: lib/rag/ingest-document.ts."
  Save-Canvas $canvas $path
}

function Draw-GenerationWorkflow($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Draw-Grid $g $palette 1080 1350
  Draw-Header $g $palette "WORKFLOW 02" "Grounded generation" "Lesson generation, MCQ generation, and chat all reuse the same retrieval core." "03 / 04"

  Draw-Card $g $palette "User action" "Generate lesson\nGenerate MCQ\nAsk question" 110 426 250 154 $palette.Secondary
  Draw-Card $g $palette "Retrieval core" "createEmbedding(query)\nLanceDB vectorSearch\nwhere lessonId = current" 415 426 250 154 $palette.Accent
  Draw-Card $g $palette "OpenAI response" "Use retrieved chunks as context\nDo not invent facts" 720 426 250 154 $palette.Critical

  Draw-Connector $g ([float[]]@(360, 503, 415, 503)) $palette.Secondary 4
  Draw-Connector $g ([float[]]@(665, 503, 720, 503)) $palette.Accent 4

  $branchY = 758
  Draw-Card $g $palette "Lesson" "generate-lesson route\n5 retrieved chunks\nsave GeneratedLesson" 90 $branchY 280 150 $palette.Warm
  Draw-Card $g $palette "MCQ" "generate-mcq route\n8 retrieved chunks\nsave LessonAssessment" 400 $branchY 280 150 $palette.Warm
  Draw-Card $g $palette "Chat" "chat route\n6 retrieved chunks\nreturn answer + sources" 710 $branchY 280 150 $palette.Warm

  Draw-Connector $g ([float[]]@(845, 580, 845, 660, 230, 660, 230, $branchY)) $palette.Critical 3
  Draw-Connector $g ([float[]]@(845, 580, 845, 660, 540, 660, 540, $branchY)) $palette.Critical 3
  Draw-Connector $g ([float[]]@(845, 580, 845, 660, 850, 660, 850, $branchY)) $palette.Critical 3

  $noteBrush = [System.Drawing.SolidBrush]::new($palette.Ink)
  $white = [System.Drawing.SolidBrush]::new($palette.White)
  try {
    Fill-Round $g $noteBrush 110 1048 860 78 6
    Draw-Text $g "The real product idea: one lesson-scoped retrieval layer drives all learning outputs." $palette.Fonts.CardBody $white 148 1074 784 28
  } finally {
    $noteBrush.Dispose()
    $white.Dispose()
  }

  Draw-Footer $g $palette "Core: lib/rag/retrieve-chunks.ts, generate-lesson.ts, generate-quiz.ts, chat-with-lesson.ts."
  Save-Canvas $canvas $path
}

function Draw-SystemMap($path, $palette) {
  $canvas = New-Canvas 1080 1350 $palette.Paper
  $g = $canvas.Graphics
  Draw-Grid $g $palette 1080 1350
  Draw-Header $g $palette "SYSTEM MAP" "Code-faithful architecture" "A compact map of the actual boundaries in the current Next.js RAG application." "04 / 04"

  $left = 92
  $mid = 400
  $right = 708
  $top = 402
  $gap = 138

  Draw-Card $g $palette "UI" "Dashboard\nLesson workspace\nTabs: docs, lessons, MCQs, chat" $left $top 270 132 $palette.Secondary
  Draw-Card $g $palette "Auth" "next-auth\ncredentials\nprotected routes" $left ($top + $gap) 270 132 $palette.Secondary

  Draw-Card $g $palette "API routes" "/documents\n/generate-lesson\n/generate-mcq\n/chat" $mid $top 270 132 $palette.Accent
  Draw-Card $g $palette "RAG orchestration" "ingestDocument\nretrieveChunks\ngenerateLesson\ngenerateQuiz\nchatWithLesson" $mid ($top + $gap) 270 156 $palette.Accent

  Draw-Card $g $palette "AI layer" "OpenAI SDK\nembeddings\nresponses API" $right $top 270 132 $palette.Critical
  Draw-Card $g $palette "Storage" "PostgreSQL via Prisma\nLanceDB lesson_chunks" $right ($top + $gap) 270 132 $palette.Warm

  Draw-Connector $g ([float[]]@(362, ($top + 66), $mid, ($top + 66))) $palette.Secondary 3
  Draw-Connector $g ([float[]]@(670, ($top + 66), $right, ($top + 66))) $palette.Accent 3
  Draw-Connector $g ([float[]]@(670, ($top + $gap + 78), $right, ($top + $gap + 78))) $palette.Accent 3
  Draw-Connector $g ([float[]]@(($mid + 135), ($top + 132), ($mid + 135), ($top + $gap))) $palette.Accent 3
  Draw-Connector $g ([float[]]@(($left + 135), ($top + 132), ($left + 135), ($top + $gap))) $palette.Secondary 3

  Draw-Card $g $palette "Vercel AI SDK position" "Not a current dependency. Useful next step for streaming UI, tool orchestration, and TypeScript AI ergonomics." 150 984 780 112 $palette.Critical

  Draw-Footer $g $palette "Current stack: Next.js, Auth.js, Prisma, PostgreSQL, OpenAI SDK, LanceDB."
  Save-Canvas $canvas $path
}

function Draw-Thumbnail($path, $palette) {
  $canvas = New-Canvas 1600 900 $palette.Paper
  $g = $canvas.Graphics
  Draw-Grid $g $palette 1600 900

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $accent = [System.Drawing.SolidBrush]::new($palette.Accent)
  $white = [System.Drawing.SolidBrush]::new($palette.White)

  try {
    Fill-Round $g $accent 96 80 112 40 20
    Draw-Text $g "RAG" $palette.Fonts.Pill $white 96 80 112 40 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    Draw-Text $g "RAG Learning Platform" $palette.Fonts.Title $ink 96 190 760 86
    Draw-Text $g "Minimal TypeScript architecture for retrieval, grounded generation, and learning workflows." $palette.Fonts.Body $muted 102 336 800 72

    Draw-Pill $g $palette "OpenAI SDK today" 102 460 196 $palette.Soft
    Draw-Pill $g $palette "Vercel AI SDK next" 320 460 214 $palette.Soft
    Draw-Pill $g $palette "LanceDB retrieval" 556 460 198 $palette.Soft

    Draw-Card $g $palette "Ingest" "Files / text" 980 144 240 104 $palette.Accent
    Draw-Card $g $palette "Retrieve" "lesson_chunks" 1280 144 240 104 $palette.Secondary
    Draw-Card $g $palette "Generate" "Lessons, MCQs, chat" 1130 416 260 112 $palette.Warm
    Draw-Card $g $palette "Sources" "Traceable answers" 1130 650 260 104 $palette.Critical

    Draw-Connector $g ([float[]]@(1220, 196, 1280, 196)) $palette.Accent 4
    Draw-Connector $g ([float[]]@(1400, 248, 1400, 330, 1260, 330, 1260, 416)) $palette.Secondary 4
    Draw-Connector $g ([float[]]@(1260, 528, 1260, 650)) $palette.Warm 4
  } finally {
    $ink.Dispose()
    $muted.Dispose()
    $accent.Dispose()
    $white.Dispose()
  }

  Save-Canvas $canvas $path
}

$cover = Join-Path $outputDir "01-rag-learning-platform-cover.png"
$ingestion = Join-Path $outputDir "02-document-ingestion-workflow.png"
$generation = Join-Path $outputDir "03-grounded-generation-workflow.png"
$systemMap = Join-Path $outputDir "04-code-faithful-system-map.png"
$thumbnail = Join-Path $outputDir "linkedin-thumbnail.png"
$captionPath = Join-Path $outputDir "linkedin-caption.txt"
$readmePath = Join-Path $outputDir "README.md"

Draw-Cover $cover $palette
Draw-IngestionWorkflow $ingestion $palette
Draw-GenerationWorkflow $generation $palette
Draw-SystemMap $systemMap $palette
Draw-Thumbnail $thumbnail $palette

$caption = @'
I have built RAG systems with LangChain, LangGraph, and Spring AI. For this project, I wanted to explore the TypeScript side with a small learning-focused RAG platform.

The current implementation is intentionally direct:

- Next.js App Router for UI and API routes
- Auth.js for protected lesson workspaces
- OpenAI SDK for embeddings and generation
- Prisma + PostgreSQL for users, lessons, documents, chunks, generated lessons, and MCQs
- LanceDB for lesson-scoped vector retrieval

The product workflow is simple:

Upload documents.
Extract, chunk, embed, and index them.
Retrieve top chunks scoped to the lesson.
Generate lessons, MCQs, and chat answers from retrieved context.

I am also looking at how this maps into Vercel AI SDK patterns next, especially for streaming responses, tool orchestration, and a cleaner TypeScript AI UX.

Good RAG still comes back to fundamentals: clean retrieval boundaries, traceable sources, predictable data flow, and interfaces that make generated content useful.

#RAG #TypeScript #VercelAI #NextJS #OpenAI #Prisma #PostgreSQL #LanceDB #LLM #GenAI #SoftwareEngineering
'@

$readme = @'
# LinkedIn Assets V5

Minimal, code-faithful LinkedIn carousel assets for the RAG Learning Platform.

Files:
- `01-rag-learning-platform-cover.png`
- `02-document-ingestion-workflow.png`
- `03-grounded-generation-workflow.png`
- `04-code-faithful-system-map.png`
- `linkedin-thumbnail.png`
- `linkedin-caption.txt`

Generated from:
- `scripts/generate-linkedin-assets-v5.ps1`
'@

Set-Content -Path $captionPath -Value $caption -Encoding UTF8
Set-Content -Path $readmePath -Value $readme -Encoding UTF8

Write-Host "Created v5 LinkedIn assets in: $outputDir"
