# Tagged PDF in Prawn: evidence

Evidence for the tagged PDF pull requests to pdf-core, prawn and prawn-table.
`tagged_report.rb` renders one 3-page report: a heading, a figure, a
label/value table, a 46-row table that continues on page 2 with a repeated
header, a paragraph that runs over a page break, a list, a link, a running
footer and page numbers.

| File | What it is |
|---|---|
| `before-prawn-2.5.0.pdf` | Rendered with released Prawn 2.5.0 and prawn-table 0.2.2 (untagged) |
| `after-tagged.pdf` | Rendered with the `tagged-pdf` branches |
| `after-tagged-pdf-ua.pdf` | The same, plus XMP metadata with `pdfuaid:part` and `DisplayDocTitle` (`--pdf-ua`), which the PRs do not add |
| `*.verapdf.html`, `*.verapdf.xml` | veraPDF 1.30.0 reports, PDF/UA-1 profile |
| `after-tagged-pdf-ua.structure.txt` | Structure tree, printed by `structure_tree.rb` |
| `pixel-diff.txt` | Before and after pages compared pixel by pixel at 60 dpi |

## Results (veraPDF 1.30.0, PDF/UA-1)

| File | Result | Failed checks |
|---|---|---|
| `before-prawn-2.5.0.pdf` | Failed: 10 rules | 1057 |
| `after-tagged.pdf` | Failed: 2 rules, 7.1-8 (Metadata) and 7.1-10 (DisplayDocTitle) | 2 |
| `after-tagged-pdf-ua.pdf` | Passed | 0 |

The tagged pages are pixel-identical to the untagged ones.

## Reproduce

```sh
git clone https://github.com/prawnpdf/prawn.git   # for the DejaVu fonts and sample image
export PRAWN_DATA=$PWD/prawn/data

bundle install
bundle exec ruby tagged_report.rb after-tagged-pdf-ua.pdf --pdf-ua
bundle exec ruby structure_tree.rb after-tagged-pdf-ua.pdf
verapdf -f ua1 after-tagged-pdf-ua.pdf

BUNDLE_GEMFILE=stock/Gemfile bundle install
BUNDLE_GEMFILE=stock/Gemfile bundle exec ruby tagged_report.rb before-prawn-2.5.0.pdf
```
