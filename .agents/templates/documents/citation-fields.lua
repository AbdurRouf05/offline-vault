-- Workflow Kit: make citations in DOCX behave like Mendeley/Zotero citations.
-- 1. Each rendered citation is wrapped in a Word field (ADDIN WF_CITATION <keys>). One click in Word shades
--    the whole citation as one block. Word never recomputes ADDIN fields, so the text stays as citeproc made it.
-- 2. The links that link-citations adds (to the reference-list entry) keep working with Ctrl+click, but they
--    get the "Citation" character style so they look like normal text instead of blue link text.
-- Must run AFTER --citeproc (doc-build.mjs passes it last). Other output formats are left untouched.

local function esc(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

local plain_links = {
  Link = function(link)
    if link.target:match('^#ref%-') then
      link.content = { pandoc.Span(link.content, { ['custom-style'] = 'Citation' }) }
      return link
    end
  end,
}

function Cite(el)
  if not FORMAT:match('docx') then return nil end
  local keys = {}
  for _, c in ipairs(el.citations) do keys[#keys + 1] = c.id end
  local instr = ' ADDIN WF_CITATION ' .. table.concat(keys, ';') .. ' '
  local open = pandoc.RawInline('openxml',
    '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
    .. '<w:r><w:instrText xml:space="preserve">' .. esc(instr) .. '</w:instrText></w:r>'
    .. '<w:r><w:fldChar w:fldCharType="separate"/></w:r>')
  local close = pandoc.RawInline('openxml', '<w:r><w:fldChar w:fldCharType="end"/></w:r>')
  local content = pandoc.Inlines(el.content):walk(plain_links)
  content:insert(1, open)
  content:insert(close)
  el.content = content
  return el
end
