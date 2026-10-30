-- Workflow Kit - number table and figure captions in DOCX ("Tabel 1. ...", "Gambar 1. ...").
-- Typst and LaTeX number captions themselves; doc-build.mjs only adds this filter for DOCX.
-- Language comes from front matter `lang` (id or en; anything else uses English labels).

local labels = {
  id = { table = 'Tabel', figure = 'Gambar' },
  en = { table = 'Table', figure = 'Figure' },
}

function Pandoc(doc)
  local lang = doc.meta.lang and pandoc.utils.stringify(doc.meta.lang):sub(1, 2):lower() or 'id'
  local L = labels[lang] or labels.en
  local count = { table = 0, figure = 0 }

  local function number(el, kind)
    local long = el.caption.long
    if #long == 0 then return nil end
    local first = long[1]
    if first.t ~= 'Plain' and first.t ~= 'Para' then return nil end
    count[kind] = count[kind] + 1
    local label = pandoc.Inlines({ pandoc.Str(L[kind]), pandoc.Space(), pandoc.Str(count[kind] .. '.'), pandoc.Space() })
    first.content = label .. first.content
    long[1] = first
    el.caption.long = long
    return el
  end

  return doc:walk({
    Table = function(t) return number(t, 'table') end,
    Figure = function(f) return number(f, 'figure') end,
  })
end
