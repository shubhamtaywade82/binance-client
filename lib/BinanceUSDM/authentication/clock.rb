# frozen_string_literal: true

require "time"

module BinanceUSDM
  module Authentication
    # Clock abstraction for timestamp management with server time synchronization.
    class Clock
      attr_reader :time_offset, :last_sync_time, :sync_interval

      # Initialize clock
      # @param sync_interval [Integer] Auto-sync interval in seconds (default: 3600)
      def initialize(sync_interval: 3600)
        @time_offset = 0
        @last_sync_time = nil
        @sync_interval = sync_interval
        @mutex = Mutex.new
      end

      # Get current timestamp in milliseconds
      # @return [Integer] Current time in ms
      def timestamp
        Time.now.to_i * 1000 + time_offset
      end

      # Get current time
      # @return [Time] Current time
      def now
        Time.now + time_offset / 1000.0
      end

      # Update time offset based on server time
      # @param server_time [Integer] Server timestamp in ms
      def sync(server_time)
        @mutex.synchronize do
          local_time = Time.now.to_i * 1000
          @time_offset = server_time - local_time
          @last_sync_time = Time.now
        end
      end

      # Sync with server using provided block
      # @yieldreturn [Integer] Server timestamp in ms
      def sync_with(&block)
        server_time = yield
        sync(server_time)
      end

      # Check if sync is needed
      # @return [Boolean]
      def sync_needed?
        return true if last_sync_time.nil?
        
        Time.now - last_sync_time > sync_interval
      end

      # Force sync if needed
      # @yieldreturn [Integer] Server timestamp in ms
      def auto_sync(&block)
        return unless sync_needed?
        
        sync_with(&block)
      end

      # Reset time offset
      def reset
        @mutex.synchronize do
          @time_offset = 0
          @last_sync_time = nil
        end
      end

      # Get human-readable offset
      # @return [String] Offset in milliseconds
      def offset_str
        "#{time_offset > 0 ? '+' : ''}#{time_offset}ms"
      end
    end
  end
end
