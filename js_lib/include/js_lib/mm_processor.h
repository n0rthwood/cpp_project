#pragma once

#include <string>
#include <vector>
#include <memory>
#include <opencv2/core/mat.hpp>
#include <opencv2/imgproc.hpp>
#include "mmdeploy/detector.hpp"
#include "mmdeploy/classifier.hpp"

namespace js_lib {

class MMProcessor {
public:
    struct DetectionResult {
        cv::Mat mask;
        cv::Rect bbox;
        float score;
        int label_id;
    };

    struct ProcessResult {
        DetectionResult detection;
        std::vector<mmdeploy_classification_t> classifications;
    };

    MMProcessor(const std::string& det_model_path, 
                const std::string& cls_model_path,
                const std::string& device = "cuda");

    std::vector<ProcessResult> process_image(const cv::Mat& image);
    
    // Format results as a string table
    std::string format_results(const std::vector<ProcessResult>& results) const;

private:
    cv::Mat slice_tensor_by_mask(const cv::Mat& image, 
                                const cv::Mat& mask,
                                const cv::Size& target_size = cv::Size(224, 224));

    std::unique_ptr<mmdeploy::Detector> detector_;
    std::unique_ptr<mmdeploy::Classifier> classifier_;
};

} // namespace js_lib
