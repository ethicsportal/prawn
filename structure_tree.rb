# Prints a PDF's structure tree. Usage: ruby structure_tree.rb FILE.pdf
require 'pdf/reader'

reader = PDF::Reader.new(ARGV.fetch(0))
objects = reader.objects
catalog = objects.deref(objects.trailer[:Root])
abort 'No structure tree: the PDF is not tagged.' unless catalog[:StructTreeRoot]

pages = objects.page_references.map(&:id)
text = ->(s) { s.start_with?("\xFE\xFF".b) ? s.byteslice(2..).force_encoding('UTF-16BE').encode('UTF-8') : s }

# Repeated identical siblings, such as table rows, are printed once with a count.
render = lambda do |node|
  node = objects.deref(node)
  kids = Array(objects.deref(node[:K])).map { |kid| objects.deref(kid) }
  content_pages = kids.select { |k| k[:Type] == :MCR }.map { |k| pages.index(k[:Pg].id) + 1 }.uniq
  annotations = kids.select { |k| k[:Type] == :OBJR }.map { |k| objects.deref(k[:Obj]) }

  details = []
  details << %(Alt "#{text[node[:Alt]]}") if node[:Alt]
  attributes = objects.deref(node[:A])
  details << "Scope #{attributes[:Scope]}" if attributes&.key?(:Scope)
  details << "content on page #{content_pages.join(', ')}" if content_pages.any?
  annotations.each { |a| details << %(link annotation "#{text[a[:Contents]]}") }

  children = kids.select { |k| k[:Type] == :StructElem }.map(&render)
  lines = children.chunk_while { |a, b| a == b }.flat_map do |run|
    run.size > 1 ? ["#{run.first.first}  × #{run.size}", *run.first.drop(1)] : run.first
  end
  ["#{node[:S]}#{details.empty? ? '' : "  (#{details.join('; ')})"}", *lines.map { |l| "  #{l}" }]
end

Array(objects.deref(objects.deref(catalog[:StructTreeRoot])[:K])).each { |k| puts render[k] }
