class TimersController < ApplicationController
  before_action :set_timer, only: [:show, :edit, :update, :destroy, :start, :pause, :stop, :resume, :reset]

  def index
    @timers = Current.user.timers.order(created_at: :desc)
    @active_timers = @timers.active
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: timer_json(@timer) }
    end
  end

  def new
    @timer = Current.user.timers.build
    @templates = Current.user.timer_templates.order(:name)
    @popular_templates = Current.user.timer_templates.popular.limit(3)
  end

  def create
    @timer = Current.user.timers.build(timer_params)
    @timer.status = 'stopped'
    @timer[:tags] = params[:timer][:tags] if params[:timer][:tags].present?
    
    # Handle countdown timer creation
    if params[:timer][:timer_type] == 'countdown'
      hours = params[:timer][:duration_hours].to_i
      minutes = params[:timer][:duration_minutes].to_i
      seconds = params[:timer][:duration_seconds].to_i
      
      total_seconds = (hours * 3600) + (minutes * 60) + seconds
      if total_seconds > 0
        @timer.target_duration = total_seconds
        @timer.remaining_duration = total_seconds
      else
        @timer.errors.add(:base, "Please set a duration for the countdown timer")
        load_templates_for_form
        render :new, status: :unprocessable_entity and return
      end
    end
    
    if @timer.save
      # Save as template if requested
      if params[:save_as_template] == '1'
        create_template_from_timer(@timer)
      end
      
      redirect_to @timer, notice: 'Timer was successfully created.'
    else
      load_templates_for_form
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Handle expiration from AJAX request
    if params[:expired]
      @timer.expire!
      respond_to do |format|
        format.json { render json: { status: 'expired' } }
        format.html { redirect_to @timer, notice: 'Timer has expired.' }
      end
      return
    end
    
    @timer[:tags] = params[:timer][:tags] if params[:timer].has_key?(:tags)
    
    if @timer.update(timer_params)
      respond_to do |format|
        format.html { redirect_to @timer, notice: 'Timer was successfully updated.' }
        format.json { render json: { success: true, notes: @timer.notes } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @timer.errors.full_messages } }
      end
    end
  end

  def destroy
    @timer.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@timer)) }
      format.html { redirect_to timers_url, notice: 'Timer was successfully deleted.' }
    end
  end

  def start
    @timer.start!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to request.referrer || timers_path, notice: 'Timer started!' }
      format.json { render json: timer_json(@timer) }
    end
  end

  def pause
    if @timer.running?
      @timer.pause!
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to request.referrer || timers_path, notice: 'Timer paused!' }
        format.json { render json: timer_json(@timer) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: 'Timer is not running.' }) }
        format.html { redirect_to request.referrer || timers_path, alert: 'Timer is not running.' }
        format.json { render json: { error: 'Timer is not running' }, status: :unprocessable_entity }
      end
    end
  end

  def resume
    if @timer.paused?
      @timer.resume!
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to request.referrer || timers_path, notice: 'Timer resumed!' }
        format.json { render json: timer_json(@timer) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: 'Timer is not paused.' }) }
        format.html { redirect_to request.referrer || timers_path, alert: 'Timer is not paused.' }
        format.json { render json: { error: 'Timer is not paused' }, status: :unprocessable_entity }
      end
    end
  end

  def stop
    if @timer.running? || @timer.paused?
      @timer.stop!
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to request.referrer || timers_path, notice: 'Timer stopped!' }
        format.json { render json: timer_json(@timer) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: 'Timer is not active.' }) }
        format.html { redirect_to request.referrer || timers_path, alert: 'Timer is not active.' }
        format.json { render json: { error: 'Timer is not active' }, status: :unprocessable_entity }
      end
    end
  end

  def reset
    @timer.reset!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to request.referrer || timers_path, notice: 'Timer reset!' }
      format.json { render json: timer_json(@timer) }
    end
  end

  private

  def set_timer
    @timer = Current.user.timers.find(params[:id])
  end

  def timer_params
    params.require(:timer).permit(:task_name, :timer_type, :notes)
  end
  
  def timer_json(timer)
    json = {
      id: timer.id,
      task_name: timer.task_name,
      status: timer.status,
      timer_type: timer.timer_type,
      start_time: timer.start_time&.iso8601,
      end_time: timer.end_time&.iso8601,
      remaining_duration: timer.remaining_duration,
      remaining_time: timer.calculate_remaining_time,
      target_duration: timer.target_duration,
      duration: timer.duration,
      is_countdown: timer.countdown?,
      is_expired: timer.expired?,
      formatted_duration: timer.formatted_duration,
      progress_percentage: timer.progress_percentage,
      tags: timer.parse_tags,
      notes: timer.notes
    }
    
    # Include updated controls HTML
    json[:controls_html] = render_to_string(
      partial: 'timers/timer_controls',
      locals: { timer: timer },
      formats: [:html]
    )
    
    json[:controls_compact_html] = render_to_string(
      partial: 'timers/timer_controls_compact', 
      locals: { timer: timer },
      formats: [:html]
    )
    
    json
  end

  def load_templates_for_form
    @templates = Current.user.timer_templates.order(:name)
    @popular_templates = Current.user.timer_templates.popular.limit(3)
  end

  def create_template_from_timer(timer)
    template_attributes = {
      name: "#{timer.task_name} Template",
      task_name: timer.task_name,
      timer_type: timer.timer_type,
      tags: timer[:tags], # Use column access, not association
      notes: timer.notes
    }
    
    # Include duration for countdown timers
    if timer.countdown? && timer.target_duration.present?
      template_attributes[:target_duration] = timer.target_duration
    end
    
    template = Current.user.timer_templates.build(template_attributes)
    
    if template.save
      flash[:notice] = (flash[:notice] || "Timer was successfully created.") + " Template '#{template.name}' was also created!"
    else
      flash[:alert] = "Timer created, but failed to save template: #{template.errors.full_messages.join(', ')}"
    end
  end
end
