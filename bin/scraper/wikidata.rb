#!/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'csv'
require 'scraped'

class Results < Scraped::JSON
  field :members do
    json[:results][:bindings].map { |result| fragment(result => Member).to_h }
  end
end

class Member < Scraped::JSON
  field :id do
    json.dig(:id, :value)
  end

  field :item do
    json.dig(:item, :value).to_s.split('/').last
  end

  field :name do
    json.dig(:name, :value)
  end

  field :area do
    json.dig(:area, :value)
  end

  field :party do
    json.dig(:party, :value)
  end

  field :start do
    json.dig(:start, :value)
  end
end

# In this case it might make more sense to fetch as CSV and output it
# directly, but this way keeps it in sync with our normal approach, and
# allows us to more easily post-process if needed
WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql?format=json&query=%s'

memberships_query = <<SPARQL
  SELECT ?id ?item ?name ?area ?party ?start WHERE {
    ?item p:P1214 ?idstatement ; p:P39 ?ps .
    ?idstatement ps:P1214 ?id FILTER(STRLEN(?id) < 20) .
    OPTIONAL { ?idstatement pq:P1810 ?riksdagName }

    ?ps ps:P39 wd:Q10655178 ; pq:P580 ?startDate .
    BIND(SUBSTR(STR(?startDate),1,10) AS ?start)

    OPTIONAL { ?ps pq:P582 ?end }
    FILTER(!BOUND(?end) || ?end > NOW())

    OPTIONAL {
      ?ps pq:P4100 ?group .
      OPTIONAL {
        ?group wdt:P1813 ?groupShort FILTER(LANG(?groupShort) = "sv")
      }
    }
    BIND(COALESCE(?groupShort, '-') AS ?party)

    OPTIONAL {
      ?ps pq:P768 ?district .
      # TODO: ONLY ?districts that are actual constituencies?
      ?district rdfs:label ?districtLabel FILTER(LANG(?districtLabel) = "sv") .
      BIND(REPLACE(STR(?districtLabel), "s? valkrets", "") AS ?area)
    }

    ?item rdfs:label ?svname FILTER(LANG(?svname) = "sv") .
    BIND(COALESCE(?riksdagName, ?svname) AS ?name)
  }
  ORDER BY ?name
SPARQL

url = WIKIDATA_SPARQL_URL % CGI.escape(memberships_query)
headers = { 'User-Agent' => 'every-politican-scrapers/sweden-riksdag-api-current' }
data = Results.new(response: Scraped::Request.new(url: url, headers: headers).response).members

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
abort 'No results' if rows.count.zero?

puts header + rows.join
