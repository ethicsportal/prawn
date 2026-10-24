# Renders the same report with stock Prawn (untagged) or with tagged PDF
# support. Usage: PRAWN_DATA=path/to/prawn/data ruby tagged_report.rb OUTPUT.pdf [--pdf-ua]
# PRAWN_DATA is the data directory of a Prawn checkout: the gem does not ship
# the DejaVu fonts or sample images.
require 'prawn'
require 'prawn/table'

output = ARGV.fetch(0)
data = ENV.fetch('PRAWN_DATA')
pdf_ua = ARGV.include?('--pdf-ua')
title = 'Annual report 2026'

tagging = Prawn::Document.method_defined?(:structure)
options = { info: { Title: title }, margin: 54 }
options.merge!(tagged: true, language: 'en-GB') if tagging
pdf = Prawn::Document.new(options)

# Stock Prawn has no structure or artifact; draw the same content untagged.
unless tagging
  def pdf.structure(*) = yield
  def pdf.artifact(*) = yield
end

pdf.font_families.update(
  'DejaVu' => {
    normal: "#{data}/fonts/DejaVuSans.ttf",
    bold: "#{data}/fonts/DejaVuSans-Bold.ttf",
  },
)
pdf.font('DejaVu', size: 10)

pdf.structure(:Document) do
  pdf.structure(:H1) { pdf.text(title, size: 20, style: :bold) }
  pdf.move_down(6)
  pdf.structure(:P) do
    pdf.text('This report shows a tagged PDF made with Prawn. ' * 3)
  end
  pdf.move_down(8)
  pdf.structure(:Figure, Alt: 'Photo of two pigs in a field') do
    pdf.image("#{data}/images/pigs.jpg", width: 160)
  end
  pdf.move_down(8)

  pdf.structure(:H2) { pdf.text('Summary', size: 14, style: :bold) }
  pdf.table(
    [['Reference', 'AR-2026'], ['Status', 'Published'], ['Owner', 'Finance']],
    cell_style: { borders: [:bottom], border_color: 'BBBBBB' },
    **(tagging ? { row_header: true } : {}),
  )
  pdf.move_down(8)

  pdf.structure(:H2) { pdf.text('Milestones', size: 14, style: :bold) }
  pdf.table(
    [%w[Milestone Due Status]] +
      (1..45).map { |i| ["Milestone #{i}", "Week #{i}", i < 30 ? 'Done' : 'Open'] },
    header: true,
    row_colors: %w[FFFFFF F2F2F2],
    cell_style: { border_color: 'BBBBBB' },
  )
  pdf.move_down(8)
  pdf.structure(:P) do
    pdf.text('This paragraph is one structure element that runs over a page break. ' * 12)
  end
  pdf.move_down(8)

  pdf.structure(:H2) { pdf.text('Notes', size: 14, style: :bold) }
  pdf.structure(:L) do
    pdf.structure(:LI) { pdf.text('- Text inside one element can run over a page break.') }
    pdf.structure(:LI) { pdf.text('- Header rows repeated on a new page are read once.') }
  end
  pdf.structure(:P) do
    pdf.text(
      "Source: <link href='https://github.com/prawnpdf/prawn'>Prawn on GitHub</link>.",
      inline_format: true,
    )
  end
  pdf.artifact(Type: :Layout) { pdf.stroke_horizontal_rule }
end

pdf.repeat(:all) { pdf.draw_text(title, at: [0, -20], size: 8) }
pdf.number_pages('Page <page> of <total>', at: [pdf.bounds.right - 100, -12], width: 100, align: :right, size: 8)

# PDF/UA identification is out of scope for the PRs: XMP metadata claiming
# PDF/UA-1, and asking viewers to show the title instead of the file name.
if pdf_ua
  pdf.state.store.root.data[:ViewerPreferences] = { DisplayDocTitle: true }
  metadata = pdf.renderer.ref!(Type: :Metadata, Subtype: :XML)
  metadata.stream << <<~XML
    <?xpacket begin="\u{FEFF}" id="W5M0MpCehiHzreSzNTczkc9d"?>
    <x:xmpmeta xmlns:x="adobe:ns:meta/">
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about=""
            xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:pdfuaid="http://www.aiim.org/pdfua/ns/id/">
          <dc:title><rdf:Alt><rdf:li xml:lang="x-default">#{title}</rdf:li></rdf:Alt></dc:title>
          <pdfuaid:part>1</pdfuaid:part>
        </rdf:Description>
      </rdf:RDF>
    </x:xmpmeta>
    <?xpacket end="w"?>
  XML
  pdf.state.store.root.data[:Metadata] = metadata
end

pdf.render_file(output)
