class TimersController < ApplicationController
  before_action :set_timer, only: [:show, :edit, :update, :destroy, :start, :pause, :stop, :resume]
  before_action :require_authentication

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
    
    if @timer.save
      redirect_to @timer, notice: 'Timer was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
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
    @timer.update(
      status: 'running',
      start_time: Time.current,
      end_time: nil
    )
    redirect_to timers_path, notice: 'Timer started!'
  end

  def pause
    if @timer.running?
      duration = @timer.calculate_duration
      @timer.update(
        status: 'paused',
        duration: duration,
        end_time: Time.current
      )
      redirect_to timers_path, notice: 'Timer paused!'
    else
      redirect_to timers_path, alert: 'Timer is not running.'
    end
  end

  def resume
    if @timer.paused?
      @timer.update(
        status: 'running',
        start_time: Time.current - (@timer.duration || 0).seconds,
        end_time: nil
      )
      redirect_to timers_path, notice: 'Timer resumed!'
    else
      redirect_to timers_path, alert: 'Timer is not paused.'
    end
  end

  def stop
    if @timer.running? || @timer.paused?
      duration = @timer.calculate_duration
      @timer.update(
        status: 'stopped',
        duration: duration,
        end_time: Time.current
      )
      redirect_to timers_path, notice: 'Timer stopped!'
    else
      redirect_to timers_path, alert: 'Timer is not active.'
    end
  end

  private

  def set_timer
    @timer = Current.user.timers.find(params[:id])
  end

  def timer_params
    params.require(:timer).permit(:task_name)
  end
end
