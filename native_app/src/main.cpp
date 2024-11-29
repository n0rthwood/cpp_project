#include <iostream>
#include <js_lib/mm_processor.h>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>

int main(int argc, char* argv[]) {
    if (argc != 4) {
        std::cerr << "Usage: " << argv[0] << " <image_path> <det_model_path> <cls_model_path>" << std::endl;
        return -1;
    }

    // Load test image
    cv::Mat image = cv::imread(argv[1]);
    if (image.empty()) {
        std::cerr << "Failed to load image: " << argv[1] << std::endl;
        return -1;
    }

    try {
        // Initialize processor with model paths
        js_lib::MMProcessor processor(
            argv[2],  // Detection model path
            argv[3],  // Classification model path
            "cuda"
        );

        // Process image
        auto results = processor.process_image(image);

        // Display formatted results
        std::cout << "\nProcessing Results:\n" << processor.format_results(results) << std::endl;

        // Visualize results
        cv::Mat output = image.clone();
        for (const auto& result : results) {
            // Draw bounding box
            cv::rectangle(output, result.detection.bbox, cv::Scalar(0, 255, 0), 2);

            // Draw mask if available
            if (!result.detection.mask.empty()) {
                cv::Mat colored_mask;
                cv::cvtColor(result.detection.mask, colored_mask, cv::COLOR_GRAY2BGR);
                colored_mask = colored_mask * cv::Scalar(0, 0, 255);
                cv::addWeighted(output, 1.0, colored_mask, 0.5, 0, output);
            }

            // Add object number
            cv::putText(output, 
                       "Object " + std::to_string(&result - &results[0] + 1),
                       cv::Point(result.detection.bbox.x, result.detection.bbox.y - 10),
                       cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0, 255, 0), 2);
        }

        // Save output image
        cv::imwrite("output.jpg", output);
        std::cout << "\nVisualization saved to output.jpg" << std::endl;

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return -1;
    }

    return 0;
}
