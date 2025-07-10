class TimersController < ApplicationController
  before_action :set_timer, only: [:show, :edit, :update, :destroy, :start, :pause, :stop, :resume, :reset]

  def index
    @timers = Current.user.timers.order(created_at: :desc)
    @active_timers = @timers.active
  end

  def show
  end

  def new
    @timer = Current.user.timers.build
  end

  def create
    @timer = Current.user.timers.build(timer_params)
    @timer.status = 'stopped'
    @timer[:tags] = params[:timer][:tags] if params[:timer][:tags].present?
    
    # Handle duration input for countdown timers
    if params[:timer][:duration_hours].present? || params[:timer][:duration_minutes].present? || params[:timer][:duration_seconds].present?
      hours = params[:timer][:duration_hours].to_i
      minutes = params[:timer][:duration_minutes].to_i
      seconds = params[:timer][:duration_seconds].to_i
      
      total_seconds = (hours * 3600) + (minutes * 60) + seconds
      if total_seconds > 0
        @timer.target_duration = total_seconds
        @timer.remaining_duration = total_seconds
      end
    end
    
    if @timer.save
      redirect_to @timer, notice: 'Timer was successfully created.'
    else
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
      redirect_to @timer, notice: 'Timer was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @timer.destroy
    redirect_to timers_url, notice: 'Timer was successfully deleted.'
  end

  def start
    @timer.start!
    respond_to do |format|
      format.html { redirect_to request.referrer || timers_path, notice: 'Timer started!' }
      format.json { render json: timer_json(@timer) }
    end
  end

  def pause
    if @timer.running?
      @timer.pause!
      respond_to do |format|
        format.html { redirect_to request.referrer || timers_path, notice: 'Timer paused!' }
        format.json { render json: timer_json(@timer) }
      end
    else
      respond_to do |format|
        format.html { redirect_to request.referrer || timers_path, alert: 'Timer is not running.' }
        format.json { render json: { error: 'Timer is not running' }, status: :unprocessable_entity }
      end
    end
  end

  def resume
    if @timer.paused?
      @timer.resume!
      respond_to do |format|
        format.html { redirect_to request.referrer || timers_path, notice: 'Timer resumed!' }
        format.json { render json: timer_json(@timer) }
      end
    else
      respond_to do |format|
        format.html { redirect_to request.referrer || timers_path, alert: 'Timer is not paused.' }
        format.json { render json: { error: 'Timer is not paused' }, status: :unprocessable_entity }
      end
    end
  end

  def stop
    if @timer.running? || @timer.paused?
      @timer.stop!
      respond_to do |format|
        format.html { redirect_to request.referrer || timers_path, notice: 'Timer stopped!' }
        format.json { render json: timer_json(@timer) }
      end
    else
      respond_to do |format|
        format.html { redirect_to request.referrer || timers_path, alert: 'Timer is not active.' }
        format.json { render json: { error: 'Timer is not active' }, status: :unprocessable_entity }
      end
    end
  end

  def reset
    @timer.reset!
    respond_to do |format|
      format.html { redirect_to request.referrer || timers_path, notice: 'Timer reset!' }
      format.json { render json: timer_json(@timer) }
    end
  end

  private

  def set_timer
    @timer = Current.user.timers.find(params[:id])
  end

  def timer_params
    params.require(:timer).permit(:task_name)
  end
  
  def timer_json(timer)
    {
      id: timer.id,
      status: timer.status,
      start_time: timer.start_time&.iso8601,
      remaining_duration: timer.calculate_remaining_time,
      target_duration: timer.target_duration,
      duration: timer.duration,
      is_countdown: timer.countdown?,
      formatted_duration: timer.formatted_duration
    }
  end
end
