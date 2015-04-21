module Hubspot
  #
  # HubSpot Engagements API
  #
  # {http://developers.hubspot.com/docs/methods/engagements/create_engagement}
  #
  class Engagement
    CREATE_ENGAGEMENT_PATH = "/engagements/v1/engagements"
    UPDATE_ENGAGEMENT_PATH = "/engagements/v1/engagements/:engagementId"
    DELETE_ENGAGEMENT_PATH = "/engagements/v1/engagements/:engagementId"
    GET_ENGAGEMENT_PATH = "/engagements/v1/engagements/:engagementId"

    NOTE = 'NOTE'         # props:  body
    TASK = 'TASK'         # props:  body, due_date, status
    CALL = 'CALL'         # TODO
    EMAIL = 'EMAIL'       # TODO
    MEETING = 'MEETING'   # TODO

    VALID_TYPES = [NOTE, TASK, CALL, EMAIL, MEETING]

    class << self
      # Create a new engagement for contact
      # {http://developers.hubspot.com/docs/methods/engagements/create_engagement}
      # @param type [String] string identifier of type of engagement
      # @param contactids [String/Array] id of contact(s) to add this engagement
      # @param params [Hash] hash of properties to update
      # @return [Hubspot::Engagement] self
      def create!(type, contactids, params={})
        unless VALID_TYPES.include?(type)
          raise Hubspot::InvalidParams, 'expecting valid Engagement Type (Note, Task, Call, Email, Meeting)'
        end

        engt_hash = { engagement: { active: true, type: type } }
        assc_hash = { associations: { contactIds: (contactids.is_a?(Array) ? contactids : [contactids]) } }
        meta_hash = { metadata: params }
        post_data = [engt_hash, assc_hash, meta_hash].inject(&:merge)

        response = Hubspot::Connection.post_json(CREATE_ENGAGEMENT_PATH, params: {}, body: post_data )
        new(response)
      end

      def create_from_email!(type, email, params={})
        if contact = Hubspot::Contact.find_by_email(email)
          create!(type, [contact.vid], params)
        end
      end

      # {http://developers.hubspot.com/docs/methods/engagements/get_engagement}
      # @return [Hubspot::Engagement] self
      def find_by_id(id)
        response = Hubspot::Connection.get_json(GET_ENGAGEMENT_PATH, {engagement_id: id})
        new(response)
      end
    end

    attr_reader :contacts, :companies
    attr_reader :properties
    attr_reader :eid, :etype

    def initialize(response_hash)
      @eid = response_hash["engagement"]["id"]
      @etype = response_hash["engagement"]["type"]
      @contacts = response_hash["associations"]["contactIds"]
      @companies = response_hash["associations"]["companyIds"]
      @properties = response_hash["metadata"]
    end

    def [](property)
      @properties[property.to_s]
    end

    def id
      @eid
    end

    def type
      @etype
    end

    def primary_contact
      @contacts.first unless @contacts.empty?
    end

    def body
      @properties["body"]
    end

    # Updates the properties of an engagement
    # {http://developers.hubspot.com/docs/methods/engagements/update_engagement}
    # @param params [Hash] hash of properties to update
    # @return [Hubspot::Engagement] self
    def update!(params)
      query = { metadata: params }
      response = Hubspot::Connection.post_json(UPDATE_ENGAGEMENT_PATH, params: { engagement_id: id }, body: query)
      @properties.merge!(params)
      self
    end

    # Archives the engagement in hubspot
    # {http://developers.hubspot.com/docs/methods/engagements/delete-engagement}
    # @return [TrueClass] true
    def destroy!
      response = Hubspot::Connection.delete_json(DELETE_ENGAGEMENT_PATH, { engagement_id: id })
      @destroyed = true
    end

    def destroyed?
      !!@destroyed
    end

  end
end