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
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
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

function New-RoundPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 16) {
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
  $path = New-RoundPath $x $y $w $h $r
  try {
    $graphics.FillPath($brush, $path)
  } finally {
    $path.Dispose()
  }
}

function Stroke-Round($graphics, $pen, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r = 16) {
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

function Draw-Line($graphics, [float]$x1, [float]$y1, [float]$x2, [float]$y2, $color, [float]$width = 2.4, [bool]$arrow = $false) {
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

function Draw-SoftGrid($graphics, $palette, [int]$width, [int]$height) {
  $pen = [System.Drawing.Pen]::new($palette.Grid, 1)
  try {
    for ($x = 72; $x -le ($width - 72); $x += 96) {
      $graphics.DrawLine($pen, $x, 70, $x, $height - 70)
    }
    for ($y = 78; $y -le ($height - 78); $y += 96) {
      $graphics.DrawLine($pen, 72, $y, $width - 72, $y)
    }
  } finally {
    $pen.Dispose()
  }
}

function Draw-BlurredOrb($graphics, $palette, [float]$x, [float]$y, [float]$size, $color) {
  for ($i = 0; $i -lt 24; $i += 1) {
    $alpha = [Math]::Max(5, 30 - $i)
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb($alpha, $color.R, $color.G, $color.B))
    $d = $size + ($i * 14)
    try {
      $graphics.FillEllipse($brush, $x - ($i * 7), $y - ($i * 7), $d, $d)
    } finally {
      $brush.Dispose()
    }
  }
}

function Draw-Badge($graphics, $palette, [string]$label, [float]$x, [float]$y, [float]$w) {
  $fill = [System.Drawing.SolidBrush]::new($palette.Surface)
  $border = [System.Drawing.Pen]::new($palette.Border, 1.4)
  $text = [System.Drawing.SolidBrush]::new($palette.Ink)
  try {
    Fill-Round $graphics $fill $x $y $w 46 23
    Stroke-Round $graphics $border $x $y $w 46 23
    Draw-Text $graphics $label $palette.Fonts.Badge $text ($x + 18) ($y + 1) ($w - 36) 44 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $fill.Dispose()
    $border.Dispose()
    $text.Dispose()
  }
}

function Draw-NextIcon($graphics, $palette, [float]$x, [float]$y, [float]$size) {
  $circle = [System.Drawing.SolidBrush]::new($palette.Ink)
  $white = [System.Drawing.SolidBrush]::new($palette.Paper)
  $pen = [System.Drawing.Pen]::new($palette.Paper, 4)
  try {
    $graphics.FillEllipse($circle, $x, $y, $size, $size)
    Draw-Text $graphics "N" $palette.Fonts.IconLetter $white ($x + 12) ($y + 6) ($size - 24) ($size - 12) ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    $graphics.DrawLine($pen, $x + 42, $y + 24, $x + 67, $y + 62)
  } finally {
    $circle.Dispose()
    $white.Dispose()
    $pen.Dispose()
  }
}

function Draw-TypeScriptIcon($graphics, $palette, [float]$x, [float]$y, [float]$size) {
  $blue = [System.Drawing.SolidBrush]::new($palette.TS)
  $white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
  try {
    Fill-Round $graphics $blue $x $y $size $size 14
    Draw-Text $graphics "TS" $palette.Fonts.IconTs $white ($x + 8) ($y + 24) ($size - 16) 44 ([System.Drawing.StringAlignment]::Far) ([System.Drawing.StringAlignment]::Center)
  } finally {
    $blue.Dispose()
    $white.Dispose()
  }
}

function Draw-VercelAiIcon($graphics, $palette, [float]$x, [float]$y, [float]$size) {
  $fill = [System.Drawing.SolidBrush]::new($palette.Ink)
  $white = [System.Drawing.SolidBrush]::new($palette.Paper)
  $spark = [System.Drawing.Pen]::new($palette.Ai, 3)
  try {
    $points = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($x + ($size / 2), $y + 11),
      [System.Drawing.PointF]::new($x + 12, $y + $size - 14),
      [System.Drawing.PointF]::new($x + $size - 12, $y + $size - 14)
    )
    $graphics.FillPolygon($fill, $points)
    Draw-Text $graphics "AI" $palette.Fonts.IconAi $white ($x + 5) ($y + 35) ($size - 10) 26 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    $graphics.DrawLine($spark, $x + $size - 5, $y + 7, $x + $size + 13, $y + 7)
    $graphics.DrawLine($spark, $x + $size + 4, $y - 2, $x + $size + 4, $y + 16)
  } finally {
    $fill.Dispose()
    $white.Dispose()
    $spark.Dispose()
  }
}

function Draw-TechCard($graphics, $palette, [string]$title, [string]$body, [string]$kind, [float]$x, [float]$y, [float]$w) {
  $fill = [System.Drawing.SolidBrush]::new($palette.Surface)
  $border = [System.Drawing.Pen]::new($palette.Border, 1.6)
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  try {
    Fill-Round $graphics $fill $x $y $w 138 22
    Stroke-Round $graphics $border $x $y $w 138 22

    if ($kind -eq "next") {
      Draw-NextIcon $graphics $palette ($x + 22) ($y + 27) 72
    } elseif ($kind -eq "ts") {
      Draw-TypeScriptIcon $graphics $palette ($x + 22) ($y + 27) 72
    } else {
      Draw-VercelAiIcon $graphics $palette ($x + 22) ($y + 27) 72
    }

    Draw-Text $graphics $title $palette.Fonts.CardTitle $ink ($x + 112) ($y + 30) ($w - 136) 30
    Draw-Text $graphics $body $palette.Fonts.CardBody $muted ($x + 112) ($y + 67) ($w - 136) 42
  } finally {
    $fill.Dispose()
    $border.Dispose()
    $ink.Dispose()
    $muted.Dispose()
  }
}

function Draw-WorkflowStage($graphics, $palette, [string]$num, [string]$title, [string]$body, [float]$x, [float]$y, [float]$w, [float]$h, $accent) {
  $surface = [System.Drawing.SolidBrush]::new($palette.Surface)
  $border = [System.Drawing.Pen]::new($palette.Border, 1.5)
  $accentBrush = [System.Drawing.SolidBrush]::new($accent)
  $accentPen = [System.Drawing.Pen]::new($accent, 2.5)
  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  $paper = [System.Drawing.SolidBrush]::new($palette.Paper)
  try {
    Fill-Round $graphics $surface $x $y $w $h 28
    Stroke-Round $graphics $border $x $y $w $h 28
    $graphics.FillEllipse($accentBrush, $x + 28, $y + 30, 48, 48)
    Draw-Text $graphics $num $palette.Fonts.StageNum $paper ($x + 28) ($y + 30) 48 48 ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Center)
    $graphics.DrawLine($accentPen, $x + 100, $y + 57, $x + $w - 32, $y + 57)
    Draw-Text $graphics $title $palette.Fonts.StageTitle $ink ($x + 30) ($y + 100) ($w - 60) 42
    Draw-Text $graphics $body $palette.Fonts.StageBody $muted ($x + 30) ($y + 151) ($w - 60) 74
  } finally {
    $surface.Dispose()
    $border.Dispose()
    $accentBrush.Dispose()
    $accentPen.Dispose()
    $ink.Dispose()
    $muted.Dispose()
    $paper.Dispose()
  }
}

function Draw-FileStack($graphics, $palette, [float]$x, [float]$y) {
  $paper = [System.Drawing.SolidBrush]::new($palette.Paper)
  $border = [System.Drawing.Pen]::new($palette.Border, 1.5)
  $accent = [System.Drawing.Pen]::new($palette.Gold, 3)
  try {
    Fill-Round $graphics $paper ($x + 16) ($y + 12) 92 108 14
    Stroke-Round $graphics $border ($x + 16) ($y + 12) 92 108 14
    Fill-Round $graphics $paper $x $y 92 108 14
    Stroke-Round $graphics $border $x $y 92 108 14
    $graphics.DrawLine($accent, $x + 18, $y + 34, $x + 72, $y + 34)
    $graphics.DrawLine($accent, $x + 18, $y + 54, $x + 66, $y + 54)
    $graphics.DrawLine($accent, $x + 18, $y + 74, $x + 58, $y + 74)
  } finally {
    $paper.Dispose()
    $border.Dispose()
    $accent.Dispose()
  }
}

function Draw-VectorGlyph($graphics, $palette, [float]$x, [float]$y) {
  $pen = [System.Drawing.Pen]::new($palette.Teal, 3)
  $dot = [System.Drawing.SolidBrush]::new($palette.Teal)
  try {
    $points = @(
      @(16, 18), @(58, 10), @(102, 38), @(76, 84), @(24, 74)
    )
    for ($i = 0; $i -lt $points.Count; $i += 1) {
      for ($j = $i + 1; $j -lt $points.Count; $j += 1) {
        if (($i + $j) % 2 -eq 0) {
          $graphics.DrawLine($pen, $x + $points[$i][0], $y + $points[$i][1], $x + $points[$j][0], $y + $points[$j][1])
        }
      }
    }
    foreach ($p in $points) {
      $graphics.FillEllipse($dot, $x + $p[0] - 6, $y + $p[1] - 6, 12, 12)
    }
  } finally {
    $pen.Dispose()
    $dot.Dispose()
  }
}

function Draw-GenerationGlyph($graphics, $palette, [float]$x, [float]$y) {
  $ink = [System.Drawing.Pen]::new($palette.Ink, 3)
  $accent = [System.Drawing.SolidBrush]::new($palette.Ai)
  try {
    $graphics.DrawLine($ink, $x + 20, $y + 35, $x + 96, $y + 35)
    $graphics.DrawLine($ink, $x + 20, $y + 58, $x + 78, $y + 58)
    $graphics.DrawLine($ink, $x + 20, $y + 81, $x + 90, $y + 81)
    $graphics.FillEllipse($accent, $x + 88, $y + 10, 18, 18)
    $graphics.FillEllipse($accent, $x + 99, $y + 24, 10, 10)
    $graphics.FillEllipse($accent, $x + 80, $y + 28, 8, 8)
  } finally {
    $ink.Dispose()
    $accent.Dispose()
  }
}

function Draw-MiniDiagram($graphics, $palette) {
  $mutedPen = [System.Drawing.Pen]::new($palette.Border, 1.5)
  try {
    $graphics.DrawLine($mutedPen, 218, 999, 982, 999)
  } finally {
    $mutedPen.Dispose()
  }

  Draw-FileStack $graphics $palette 118 940
  Draw-Line $graphics 245 994 370 994 $palette.Border 2.4 $true
  Draw-VectorGlyph $graphics $palette 423 949
  Draw-Line $graphics 562 994 692 994 $palette.Border 2.4 $true
  Draw-GenerationGlyph $graphics $palette 742 948

  $ink = [System.Drawing.SolidBrush]::new($palette.Ink)
  $muted = [System.Drawing.SolidBrush]::new($palette.Muted)
  try {
    Draw-Text $graphics "Documents" $palette.Fonts.MicroTitle $ink 96 1070 140 28 ([System.Drawing.StringAlignment]::Center)
    Draw-Text $graphics "chunk + embed" $palette.Fonts.Micro $muted 88 1102 156 24 ([System.Drawing.StringAlignment]::Center)
    Draw-Text $graphics "LanceDB" $palette.Fonts.MicroTitle $ink 410 1070 140 28 ([System.Drawing.StringAlignment]::Center)
    Draw-Text $graphics "lesson scoped retrieval" $palette.Fonts.Micro $muted 368 1102 222 24 ([System.Drawing.StringAlignment]::Center)
    Draw-Text $graphics "Generation" $palette.Fonts.MicroTitle $ink 728 1070 148 28 ([System.Drawing.StringAlignment]::Center)
    Draw-Text $graphics "lessons + MCQs + chat" $palette.Fonts.Micro $muted 704 1102 210 24 ([System.Drawing.StringAlignment]::Center)
  } finally {
    $ink.Dispose()
    $muted.Dispose()
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$outputDir = Join-Path $repoRoot "linkedin-assets-v6"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$display = New-Family "Aptos Display" "Segoe UI"
$textFamily = New-Family "Aptos" "Segoe UI"
$monoFamily = New-Family "Cascadia Code" "Consolas"

$palette = [PSCustomObject]@{
  Paper = New-Color "#F8F4EA"
  Surface = New-Color "#FFFDF7"
  Ink = New-Color "#111827"
  Muted = New-Color "#5B6472"
  Subtle = New-Color "#8C7452"
  Border = New-Color "#DCD3C2"
  Grid = New-Color "#EDE5D6" 95
  Gold = New-Color "#B98228"
  Teal = New-Color "#0F766E"
  Ai = New-Color "#2563EB"
  TS = New-Color "#3178C6"
}

$palette | Add-Member -MemberType NoteProperty -Name Fonts -Value ([PSCustomObject]@{
  Eyebrow = New-Font $monoFamily 18 ([System.Drawing.FontStyle]::Bold)
  Title = New-Font $display 78 ([System.Drawing.FontStyle]::Bold)
  Subtitle = New-Font $textFamily 31
  Badge = New-Font $textFamily 18 ([System.Drawing.FontStyle]::Bold)
  CardTitle = New-Font $display 25 ([System.Drawing.FontStyle]::Bold)
  CardBody = New-Font $textFamily 19
  StageNum = New-Font $textFamily 22 ([System.Drawing.FontStyle]::Bold)
  StageTitle = New-Font $display 31 ([System.Drawing.FontStyle]::Bold)
  StageBody = New-Font $textFamily 21
  IconLetter = New-Font $display 47 ([System.Drawing.FontStyle]::Bold)
  IconTs = New-Font $display 32 ([System.Drawing.FontStyle]::Bold)
  IconAi = New-Font $display 20 ([System.Drawing.FontStyle]::Bold)
  MicroTitle = New-Font $textFamily 20 ([System.Drawing.FontStyle]::Bold)
  Micro = New-Font $textFamily 16
  Footer = New-Font $textFamily 19
  Mono = New-Font $monoFamily 17
})

$canvas = New-Canvas 1200 1500 $palette.Paper
$g = $canvas.Graphics

Draw-SoftGrid $g $palette 1200 1500
Draw-BlurredOrb $g $palette 874 84 280 $palette.Ai
Draw-BlurredOrb $g $palette -60 1090 320 $palette.Gold

$border = [System.Drawing.Pen]::new($palette.Border, 1.6)
$paperBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(215, $palette.Paper.R, $palette.Paper.G, $palette.Paper.B))
$ink = [System.Drawing.SolidBrush]::new($palette.Ink)
$muted = [System.Drawing.SolidBrush]::new($palette.Muted)
$subtle = [System.Drawing.SolidBrush]::new($palette.Subtle)
$gold = [System.Drawing.SolidBrush]::new($palette.Gold)

try {
  Fill-Round $g $paperBrush 52 52 1096 1396 34
  Stroke-Round $g $border 52 52 1096 1396 34

  Draw-Text $g "RAG LEARNING PLATFORM" $palette.Fonts.Eyebrow $subtle 96 104 470 34
  Draw-Badge $g $palette "Next.js" 660 96 122
  Draw-Badge $g $palette "Vercel AI SDK" 800 96 188
  Draw-Badge $g $palette "TypeScript" 1006 96 138

  Draw-Text $g "RAG Learning Platform" $palette.Fonts.Title $ink 92 166 1000 142
  Draw-Text $g "Document-grounded AI lessons in TypeScript: upload sources, index chunks, retrieve context, generate lessons, MCQs, and chat." $palette.Fonts.Subtitle $muted 98 336 964 122

  Draw-TechCard $g $palette "Next.js" "App Router + APIs" "next" 92 524 322
  Draw-TechCard $g $palette "Vercel AI SDK" "Streaming + AI UX" "ai" 439 524 322
  Draw-TechCard $g $palette "TypeScript" "Typed stack logic" "ts" 786 524 322

  Draw-WorkflowStage $g $palette "1" "Ingest" "Parsed -> chunked -> embedded -> indexed." 92 724 322 268 $palette.Gold
  Draw-WorkflowStage $g $palette "2" "Retrieve" "Embedding search filtered by lessonId." 439 724 322 268 $palette.Teal
  Draw-WorkflowStage $g $palette "3" "Generate" "Context grounds lessons, MCQs, and chat." 786 724 322 268 $palette.Ai

  $stripFill = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(232, 255, 253, 247))
  try {
    Fill-Round $g $stripFill 92 1040 1016 78 22
    Stroke-Round $g $border 92 1040 1016 78 22
    Draw-Text $g "Post-ready story" $palette.Fonts.CardTitle $ink 126 1063 260 28
    Draw-Text $g "Sources, retrieval boundaries, persisted outputs, and a real lesson workspace." $palette.Fonts.Footer $muted 386 1061 682 34
  } finally {
    $stripFill.Dispose()
  }

  $noteFill = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(238, 255, 253, 247))
  try {
    Fill-Round $g $noteFill 92 1164 1016 138 22
    Stroke-Round $g $border 92 1164 1016 138 22
    Draw-Text $g "Code-faithful note" $palette.Fonts.CardTitle $ink 124 1190 260 30
    Draw-Text $g "The repo currently uses the OpenAI SDK directly for embeddings and generation. Vercel AI SDK is framed here as the TypeScript AI framework direction I am exploring next." $palette.Fonts.Footer $muted 124 1228 944 56
  } finally {
    $noteFill.Dispose()
  }

  $g.FillRectangle($gold, 96, 1364, 64, 4)
  Draw-Text $g "RAG fundamentals > framework hype: retrieval boundaries, source traceability, predictable UX." $palette.Fonts.Footer $ink 184 1345 820 42
  Draw-Text $g "#RAG  #NextJS  #VercelAI  #TypeScript" $palette.Fonts.Mono $muted 184 1390 650 28
} finally {
  $border.Dispose()
  $paperBrush.Dispose()
  $ink.Dispose()
  $muted.Dispose()
  $subtle.Dispose()
  $gold.Dispose()
}

Save-Canvas $canvas (Join-Path $outputDir "linkedin-post-ready.png")

$caption = @"
I have built RAG systems with LangChain, LangGraph, and Spring AI.

For this build, I wanted to explore the TypeScript AI stack more intentionally.

So I put together a small RAG learning platform with:

- Next.js App Router for the product and API surface
- TypeScript across the app boundaries
- Prisma + PostgreSQL for relational state
- LanceDB for lesson-scoped vector search
- OpenAI SDK for embeddings and generation today
- Vercel AI SDK patterns as the next exploration for streaming responses, tool orchestration, and cleaner AI UX

The workflow is simple but important:

Upload documents.
Extract and chunk the content.
Create embeddings.
Retrieve grounded context per lesson.
Generate lessons, MCQs, and chat responses with source-aware context.

The more RAG systems I build, the more I come back to the fundamentals: clean retrieval boundaries, traceable sources, predictable data flow, and UX that makes generated content useful instead of magical-looking but hard to trust.

Still a LangChain, LangGraph, and Spring AI veteran at heart, but the TypeScript ecosystem is getting seriously interesting.

#RAG #NextJS #VercelAI #TypeScript #OpenAI #Prisma #PostgreSQL #LanceDB #LLM #GenAI #SoftwareEngineering
"@

Set-Content -Path (Join-Path $outputDir "linkedin-caption.txt") -Value $caption -Encoding UTF8

$readme = @"
# LinkedIn Assets v6

Primary post image:

- `linkedin-post-ready.png` - 1200 x 1500 LinkedIn feed image

Supporting copy:

- `linkedin-caption.txt`

Design intent:

- Minimal, elegant, post-ready composition.
- Includes Next.js, Vercel AI SDK, and TypeScript visual badges.
- Keeps the architecture truthful: the repo currently uses OpenAI SDK directly, while Vercel AI SDK is framed as the TypeScript AI framework exploration path.
"@

Set-Content -Path (Join-Path $outputDir "README.md") -Value $readme -Encoding UTF8

Write-Host "Generated LinkedIn v6 assets in $outputDir"
