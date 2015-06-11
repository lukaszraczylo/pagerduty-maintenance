#!/usr/bin/env ruby

# Script puts specific PD project into maintenance mode.
# Needs two ENV variables:
#   - PD_API_KEY ( pagerDuty api access key, with write permissions )
#   - PD_PROJECT_NAME ( pagerDuty project name - custom part of the URL you log in with )
# Needs two parameters:
#   - Project ( which project should it put into maintenance )
#   - Time ( ... and for how long )

# require 'rails'
require 'trollop'
require 'httparty'
require 'table_print'
require 'awesome_print'
require 'time-lord'
require 'chronic'

$pd_base_url = "https://#{ENV['PD_PROJECT_NAME']}.pagerduty.com/api/v1/"

class PDMaintenance
  include HTTParty
  def self.run
    $params = self.parse
    @options = {
      :headers => {
      "Authorization" => "Token token=#{ENV['PD_API_KEY']}",
      "Content-type" => "application/json"},
      :output => 'json'
    }
    self.pagerduty
  end

  def self.pagerduty
    # List all the available PD projects together with their PD schedules IDs
    if $params.list_projects && ! $params.project_given
      if $params.filter_given
        @options[:query] = {
          :query => $params.filter
        }
      end
      p_json = JSON.parse(self.get($pd_base_url + 'services', @options).body)
      table_data = Array.new
      longest_entry = 20
      p_json['services'].each do |s|
        tmp_data = {
          :service_name   => "#{s['name']} (#{s['id']})",
          :created        => Chronic.parse(s['created_at']).ago.to_words,
          :status         => s['status'],
          :last_incident  => s['last_incident_timestamp'] == nil ? "never" : Chronic.parse(s['last_incident_timestamp']).ago.to_words,
          :incidents      => s['incident_counts']['total'],
        }
        # checking for longest entry in the array of hashes to set appropriate table width
        tmp_data[:service_name].length > longest_entry ? longest_entry = tmp_data[:service_name].length : nil
        table_data.push(tmp_data)
      end
      tp.set :max_width, longest_entry
      tp table_data

    elsif $params.project_given && ! $params.time

      @options[:query] = {
        "service_ids" => $params.project,
        "include[]" => 'teams',
        "filter" => 'ongoing'
      }
      p_json = JSON.parse(self.get($pd_base_url + "maintenance_windows", @options).body)
      if p_json['maintenance_windows'].count > 0
        longest_entry = 20
        table_data = Array.new
        p_json['maintenance_windows'].each do |mw|
          mw['description'].length > longest_entry ? longest_entry = mw['description'].length : nil
          projects_included = Array.new
          mw['services'].each do |pi|
            projects_included.push(pi['id'])
          end
          tmp_data = {
            :maintenance_window      => mw['id'],
            :projects     => projects_included.join(', '),
            :start_time   => Chronic.parse(mw['start_time']).ago.to_words,
            :end_time     => Chronic.parse(mw['end_time']),
            :description  => mw['description']
          }
          table_data.push(tmp_data)
        end
        tp.set :max_width, longest_entry
        tp table_data
      else
        puts "No active maintenance windows for specified project (#{$params.project})."
      end


    elsif $params.project_given && $params.time_given
      description = $params.description_given ? $params.description : "Automated maintenance mode ( created by: #{ENV['USER']} )"
      @options[:body] = {
        "maintenance_window" => {
          "service_ids"   => $params.project,
          "start_time"      => Time.now,
          "end_time"        => Time.now + $params.time.to_i * 60,
          "description"     => description
        }
      }.to_json
      p_json = JSON.parse(self.post($pd_base_url + "maintenance_windows", @options).body)
      if p_json['maintenance_window']
        puts "Maintenance window #{p_json['maintenance_window']['id']} has been created for service #{$params.project}\nWindow starts #{Time.now} and expires #{Time.now + $params.time.to_i * 60}"
        $params.project.each do |p|
         puts "To manage maintenance mode visit: https://#{ENV['PD_PROJECT_NAME']}.pagerduty.com/services/#{p}"
        end
      end
    end
  end

  def self.parse
    opts = Trollop::options do
      opt :project, "Pick specific PagerDuty service.", :type => :strings
      opt :time, "Enable maintenance window for specific time (in minutes).", :type => :string
      opt :list_projects, "Shows list of the services together with their ID"
      opt :description, "Optional description for maintenance window.", :type => :string
      opt :filter, "Search and apply for services matching the filter", :type => :string
    end
    return opts
  end
end

runme = PDMaintenance.run