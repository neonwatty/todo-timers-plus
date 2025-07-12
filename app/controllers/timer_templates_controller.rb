class TimerTemplatesController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_timer_template, only: [:show, :edit, :update, :destroy, :create_timer]

  def index
    @timer_templates = Current.user.timer_templates.includes(:user)
    
    # Sort by usage and recency
    @popular_templates = @timer_templates.most_used.limit(6)
    @recent_templates = @timer_templates.recently_used.limit(6)
    @all_templates = @timer_templates.order(:name)
  end

  def show
  end

  def new
    @timer_template = Current.user.timer_templates.build
    
    # If creating from timer, pre-populate
    if params[:from_timer_id].present?
      timer = Current.user.timers.find(params[:from_timer_id])
      @timer_template.task_name = timer.task_name
      @timer_template.timer_type = timer.timer_type || 'stopwatch'
      @timer_template.target_duration = timer.target_duration
      @timer_template.tags = timer[:tags]
    end
  end

  def create
    @timer_template = Current.user.timer_templates.build(timer_template_params)
    
    if @timer_template.save
      respond_to do |format|
        format.html { redirect_to @timer_template, notice: 'Template created successfully!' }
        format.turbo_stream { 
          flash.now[:notice] = 'Template created successfully!'
          render turbo_stream: [
            turbo_stream.prepend("templates_list", partial: "timer_template_card", locals: { template: @timer_template }),
            turbo_stream.replace("flash", partial: "shared/flash")
          ]
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @timer_template.update(timer_template_params)
      respond_to do |format|
        format.html { redirect_to @timer_template, notice: 'Template updated successfully!' }
        format.turbo_stream { 
          flash.now[:notice] = 'Template updated successfully!'
          render turbo_stream: [
            turbo_stream.replace(dom_id(@timer_template), partial: "timer_template_card", locals: { template: @timer_template }),
            turbo_stream.replace("flash", partial: "shared/flash")
          ]
        }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @timer_template.destroy
    
    respond_to do |format|
      format.html { redirect_to timer_templates_path, notice: 'Template deleted successfully!' }
      format.turbo_stream { 
        flash.now[:notice] = 'Template deleted successfully!'
        render turbo_stream: [
          turbo_stream.remove(dom_id(@timer_template)),
          turbo_stream.replace("flash", partial: "shared/flash")
        ]
      }
    end
  end

  # Create a new timer from this template
  def create_timer
    timer = @timer_template.create_timer_for_user(Current.user)
    
    if timer.persisted?
      redirect_to timers_path, notice: "Timer created from '#{@timer_template.name}' template!"
    else
      redirect_to timer_templates_path, alert: "Failed to create timer: #{timer.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_timer_template
    @timer_template = Current.user.timer_templates.find(params[:id])
  end

  def timer_template_params
    params.require(:timer_template).permit(:name, :task_name, :timer_type, :target_duration, :tags, :notes,
                                           :duration_hours, :duration_minutes, :duration_seconds)
                                   .tap do |template_params|
      # Handle duration conversion for countdown templates
      if template_params[:timer_type] == 'countdown'
        hours = template_params.delete(:duration_hours).to_i
        minutes = template_params.delete(:duration_minutes).to_i
        seconds = template_params.delete(:duration_seconds).to_i
        
        total_seconds = (hours * 3600) + (minutes * 60) + seconds
        template_params[:target_duration] = total_seconds if total_seconds > 0
      end
    end
  end
end
