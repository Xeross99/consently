require "digest"

module Consently
  # Records what the visitor agreed to, when, and against which policy
  # version - the proof the GDPR asks for. The cookie remains the source of
  # truth for what runs; this is bookkeeping.
  class ConsentsController < ApplicationController
    def create
      ConsentRecord.create!(
        categories: Array(params[:categories]).map(&:to_s).join(","),
        consent_version: params[:version].to_s,
        scope: Consently.scope_for(request).to_s.presence,
        subject: consent_subject,
        user_agent: request.user_agent.to_s.first(255),
        ip_hash: hashed_ip
      )

      head :no_content
    rescue ActiveRecord::StatementInvalid => error
      # Almost always the migration from `rails g consently:consent_log` not
      # having been run. The visitor's choice already took effect in their
      # browser, so this stays quiet and only complains in the log.
      Rails.logger.warn("[consently] could not record consent: #{error.message}")
      head :no_content
    end

    private

    # Nil unless the host application says who this is - a public site logs
    # decisions, not people.
    def consent_subject
      resolver = Consently.config.consent_subject
      return nil unless resolver

      resolver.call(request).to_s.presence
    end

    # An IP address identifies a person; a salted digest of one still tells us
    # two records came from the same visitor without storing who they are.
    def hashed_ip
      Digest::SHA256.hexdigest("consently-#{Rails.application.secret_key_base}-#{request.remote_ip}")
    end
  end
end
