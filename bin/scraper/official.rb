#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'

class MembersList < Scraped::JSON
  field :members do
    json[:personlista][:person].map { |mem| fragment(mem => MemberItem) }.select(&:current?).sort_by(&:seat).map(&:to_h)
  end
end

class MemberItem < Scraped::JSON
  def current?
    current_memberships.any?
  end

  field :id do
    json[:intressent_id]
  end

  field :sourceid do
    json[:sourceid]
  end

  field :name do
    json[:sorteringsnamn].split(',').reverse.join(' ')
  end

  field :party do
    json[:parti]
  end

  field :area do
    json[:valkrets]
  end

  field :seat do
    memberdata[:ordningsnummer].to_i
  end

  field :start do
    memberdata[:from].split(' ').first
  end

  private

  def today
    @today ||= Date.today.to_s
  end

  def current_memberships
    json[:personuppdrag][:uppdrag].select do |mem|
      (mem[:organ_kod] == 'kam') && (%w[Tjänstgörande Ersättare].include? mem[:status]) && (mem[:from] <= today) && (mem[:tom] > today)
    end
  end

  def memberdata
    return unless current?
    binding.pry if current_memberships.count > 1
    current_memberships.first
  end
end

url = 'http://data.riksdagen.se/personlista/?iid=&fnamn=&enamn=&f_ar=&kn=&parti=&valkrets=&rdlstatus=samtliga&org=&utformat=json&sort=sorteringsnamn&sortorder=asc&termlista='
data = Scraped::Scraper.new(url => MembersList).scraper.members

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
puts header + rows.join
