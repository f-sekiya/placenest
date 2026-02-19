module Places
  class CurrentPlaceResolver
    def initialize(user:)
      @user = user
    end

    def for_index(place_id:)
      place = if place_id.present?
                @user.places.find_by(id: place_id)
              else
                @user.unclassified_place
              end
      place || @user.places.first
    end

    def for_item(params_place_id:, fallback_place_id: nil)
      place_id = params_place_id.presence || fallback_place_id.presence
      return @user.places.find(place_id) if place_id.present?

      @user.unclassified_place
    end

    def for_return(return_place_id:, deleted_id:, fallback_parent:)
      place = @user.places.find_by(id: return_place_id) ||
              @user.unclassified_place ||
              @user.places.first

      return place unless place&.id == deleted_id

      fallback_parent ||
        @user.unclassified_place ||
        @user.places.where.not(id: deleted_id).first
    end
  end
end
