module MapGenerator
  class GenerateImageJob < ApplicationJob
    class << self
      def point_to_image_x_y(lat, lon, width, height)
        x = ((lon + 180.0) / 360.0 * width).round
        y = ((90.0 - lat) / 180.0 * height).round
        [x, y]
      end
    end

    def perform
      coords = Endpoint.where("coordinates IS NOT NULL").pluck(:coordinates)
      coords.each { plot(it.x, it.y) }

      add_timestamp

      image.write_to_file(Rails.root.join("public/images/gen/map.png").to_s)
    end

    private

    def plot(lat, lon, radius: 5, color: [255, 0, 0])
      x, y = self.class.point_to_image_x_y(lat, lon, image.width, image.height)

      image { it.draw_circle(color, x, y, 3, fill: true) }
    end

    def add_timestamp
      text = Vips::Image.text(Time.now.utc.to_s, dpi: 72, font: "mono 12")
      bg = Vips::Image.black(text.width + 8, text.height + 8, bands: 3)
        .new_from_image([0, 0, 0])
        .copy(interpretation: :srgb)
        .bandjoin([128]) # 50% transparency

      # padding from the edge
      padding = 10

      text_rgb = text.new_from_image([255, 255, 255])
        .bandjoin(text)
        .copy(interpretation: :srgb)

      x = image.width - text.width - padding
      y = image.height - text.height - padding
      image { it.composite2(bg, :over, x: x - 4, y: y - 4) }
      image { it.composite2(text_rgb, :over, x:, y:) }
    end

    private

    def source_path
      Rails.root.join("data/images/world.png").to_s
    end

    def image
      @image ||= Vips::Image.new_from_file(source_path).copy_memory
      @image = yield @image if block_given?
      @image
    end
  end
end
