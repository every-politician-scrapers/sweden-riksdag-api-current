#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'daff'
require 'pry'

wikidata = CSV.table('data/wikidata.csv')
official = CSV.table('data/official.csv')

columns = wikidata.headers & official.headers
wikidata_tc = [columns, *wikidata.map { |r| r.values_at(*columns) }]
official_tc = [columns, *official.map { |r| r.values_at(*columns) }]

wikidata_tv = Daff::TableView.new(wikidata_tc)
official_tv = Daff::TableView.new(official_tc)
alignment = Daff::Coopy.compare_tables(wikidata_tv, official_tv).align

table_diff = Daff::TableView.new(data_diff = [])

flags = Daff::CompareFlags.new
flags.ordered = false
flags.unchanged_context = 0
flags.show_unchanged_columns = true

highlighter = Daff::TableDiff.new(alignment, flags)
highlighter.hilite(table_diff)

puts data_diff.sort_by { |r| [r.first, r.last] }.reverse.map(&:to_csv)
