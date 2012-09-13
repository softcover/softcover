Fabricator(:book_medium) do
  name "MyString"
  book_id 1
  url "MyString"
end

Fabricator(:pdf, from: :book_medium) do
  type 'BookMedia::Pdf'
end

Fabricator(:screencasts, from: :book_medium) do
  type 'BookMedia::Screencasts'
end
