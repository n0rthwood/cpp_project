#include "js_lib/mm_processor.h"
#include <sstream>

namespace {

// Helper function to format results using simple string formatting
std::string format_results_table(const std::vector<js_lib::MMProcessor::ProcessResult>& results) {
    std::stringstream output;
    
    // Header
    output << "Detection                                  Classification\n";
    output << "----------------------------------------  ----------------------------------------\n";
    
    for (const auto& result : results) {
        std::stringstream det_ss;
        det_ss << "Label: " << result.detection.label_id << "\n"
               << "Score: " << result.detection.score << "\n"
               << "BBox: (" << result.detection.bbox.x << ", " << result.detection.bbox.y << ", "
               << result.detection.bbox.width << ", " << result.detection.bbox.height << ")";
        
        std::stringstream cls_ss;
        for (const auto& cls : result.classifications) {
            cls_ss << "Label: " << cls.label_id << "\n"
                  << "Score: " << cls.score << "\n";
        }
        
        output << det_ss.str() << "  " << cls_ss.str() << "\n";
        output << "----------------------------------------  ----------------------------------------\n";
    }
    
    return output.str();
}

} // anonymous namespace

namespace js_lib {

MMProcessor::MMProcessor(const std::string& det_model_path,
                       const std::string& cls_model_path,
                       const std::string& device) {
    // Initialize detector and classifier with the provided model paths
    detector_ = std::make_unique<mmdeploy::Detector>(
        mmdeploy::Model{det_model_path}, 
        mmdeploy::Device{device}
    );
    
    classifier_ = std::make_unique<mmdeploy::Classifier>(
        mmdeploy::Model{cls_model_path}, 
        mmdeploy::Device{device}
    );
}

std::vector<MMProcessor::ProcessResult> MMProcessor::process_image(const cv::Mat& image) {
    std::vector<ProcessResult> results;
    
    // Run detection
    auto detections = detector_->Apply(image);
    
    // Process each detection
    for (const auto& det : detections) {
        ProcessResult result;
        
        // Fill detection result
        result.detection.label_id = det.label_id;
        result.detection.score = det.score;
        result.detection.bbox = cv::Rect(det.bbox.left, det.bbox.top,
                                       det.bbox.right - det.bbox.left,
                                       det.bbox.bottom - det.bbox.top);
        
        // Extract mask if available
        if (det.mask && det.mask->data) {
            cv::Mat mask(det.mask->height, det.mask->width, CV_8UC1, det.mask->data);
            cv::resize(mask, mask, image.size(), 0, 0, cv::INTER_LINEAR);
            result.detection.mask = mask.clone();
        }
        
        // Prepare region for classification
        cv::Mat roi;
        if (!result.detection.mask.empty()) {
            roi = slice_tensor_by_mask(image, result.detection.mask);
        } else {
            roi = image(result.detection.bbox).clone();
            cv::resize(roi, roi, cv::Size(224, 224));
        }
        
        // Run classification on the region
        auto classifications = classifier_->Apply(roi);
        result.classifications = std::vector<mmdeploy_classification_t>(classifications.begin(), classifications.end());
        
        results.push_back(std::move(result));
    }
    
    return results;
}

cv::Mat MMProcessor::slice_tensor_by_mask(const cv::Mat& image, 
                                        const cv::Mat& mask,
                                        const cv::Size& target_size) {
    // Create a mask with the same size as the image
    cv::Mat resized_mask;
    if (mask.size() != image.size()) {
        cv::resize(mask, resized_mask, image.size(), 0, 0, cv::INTER_LINEAR);
    } else {
        resized_mask = mask;
    }
    
    // Ensure mask is CV_8UC1
    cv::Mat binary_mask;
    if (resized_mask.type() != CV_8UC1) {
        resized_mask.convertTo(binary_mask, CV_8UC1);
    } else {
        binary_mask = resized_mask;
    }
    
    cv::Mat masked;
    image.copyTo(masked, binary_mask);
    
    cv::Mat roi;
    cv::resize(masked, roi, target_size);
    return roi;
}

std::string MMProcessor::format_results(const std::vector<ProcessResult>& results) const {
    return format_results_table(results);
}

} // namespace js_lib
