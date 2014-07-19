module SquashManyDuplicatesMixin
  def self.included(mixee)
    mixee.class_eval do

      # GET /venues/duplicates
      def duplicates
        @page_title = "Duplicate #{model_class} Squasher"
        @type = params[:type]
        @grouped_venues = @grouped_events = model_class.find_duplicates_by_type(@type)
      rescue ArgumentError => e
        @grouped_venues = @grouped_events = {}
        flash[:failure] = e.to_s
      end

      # POST /venues/squash_multiple_duplicates
      def squash_many_duplicates
        master = model_class.find_by_id(params[:master_id])
        duplicate_ids = params.keys.grep(/^duplicate_id_\d+$/){|t| params[t].to_i}
        duplicates = model_class.where(id: duplicate_ids)

        squasher = model_class.squash(master, duplicates)
        if squasher.success
          flash[:success] = squasher.success
        else
          flash[:failure] = squasher.failure
        end
        redirect_to action: "duplicates", type: params[:type]
      end

      private

      def model_class
        # Derive model class from controller name
        controller_name.singularize.titleize.constantize
      end
    end
  end
end
