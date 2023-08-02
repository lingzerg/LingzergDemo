// MyRendering.cpp : This file contains the 'main' function. Program execution begins and ends there.
//
#include "rtweekend.h"

struct Pixel {
    int r;
    int g;
    int b;
};

#include "color.h"
#include "hittable_list.h"
#include "sphere.h"
#include "camera.h"

#include <iostream>
#include <fstream>
#include <thread>
#include <mutex>
#include <future>
#include <atomic>

/****** Image ******/
const auto aspect_ratio = 16.0 / 9.0;
const int image_width = 400;
const int image_height = static_cast<int>(image_width / aspect_ratio);
const int samples_per_pixel = 100;


const int J = 225;
const int I = 400;


/****** World ******/
hittable_list world;

/****** Camera ******/
camera cam;

std::vector<Pixel> pixelList(90000);
std::mutex pixelList_mutex;
std::atomic<int> tasks_completed(0);

color ray_color(const ray& r, const hittable& world, int depth) {
    hit_record rec;

    // If we've exceeded the ray bounce limit, no more light is gathered.
    if (depth <= 0)
        return color(0, 0, 0);

    if (world.hit(r, 0, infinity, rec)) {
        point3 target = rec.p + rec.normal + random_in_unit_sphere();
        return 0.5 * ray_color(ray(rec.p, target - rec.p), world, depth - 1);
    }
    vec3 unit_direction = unit_vector(r.direction());
    auto t = 0.5 * (unit_direction.y() + 1.0);
    return (1.0 - t) * color(1.0, 1.0, 1.0) + t * color(0.5, 0.7, 1.0);
}

Pixel render(int i, int j) {
    color pixel_color(0, 0, 0);
    for (int s = 0; s < samples_per_pixel; ++s) {
        auto u = (i + random_double()) / (image_width - 1);
        auto v = (j + random_double()) / (image_height - 1);
        ray r = cam.get_ray(u, v);
        int max_depth = 50;
        pixel_color += ray_color(r, world, max_depth);
    }
    return write_color(std::cout, pixel_color, samples_per_pixel);
}

// �̺߳���
void worker(int start, int end) {
    for (int k = start; k < end; ++k) {
        int j = k / 400;
        int i = k % 400;
        int index = i + j*400;
        
        // ��������д��vector
        Pixel p = render(i, 225-j);

        std::unique_lock<std::mutex> lock(pixelList_mutex);
        pixelList[index] = p;
        lock.unlock();
        // ����������������
        tasks_completed.fetch_add(1);
    }
}

int main() {
    
    
    // ��¼��ʼʱ��
    auto start_time = std::chrono::high_resolution_clock::now();

    /****** World ******/
    world.add(make_shared<sphere>(point3(0, 0, -1), 0.5));
    world.add(make_shared<sphere>(point3(0, -100.5, -1), 100));

    
    /****** Render ******/ 

    //std::cout << "P3\n" << image_width << ' ' << image_height << "\n255\n";

    const int num_threads = 12;
    const int total_tasks = 90000;
    const int tasks_per_thread = 7500;

    std::vector<std::thread> threads; // �洢�̵߳�vector
    std::mutex results_mutex; // ����results�Ļ�����
    std::vector<std::future<void>> futures;

    // ʹ��std::async�����̲߳���ȡstd::future
    for (int t = 0; t < num_threads; ++t) {
        int start = t * tasks_per_thread;
        int end = (t == num_threads - 1) ? total_tasks : start + tasks_per_thread;
        futures.push_back(std::async(std::launch::async, worker, start, end));
    }

    // ����̵߳�ִ�н���
    while (tasks_completed.load() < total_tasks) {
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
        std::cout << "Tasks completed: " << tasks_completed.load() << "/" << total_tasks << std::endl;
    }

    // �ȴ������߳����
    for (auto& f : futures) {
        f.wait();
    }

    //for (int j = image_height - 1; j >= 0; --j) {
    //    std::cerr << "\rScanlines remaining: " << j << ' ' << std::flush;
    //    for (int i = 0; i < image_width; ++i) {
    //        color pixel_color(0, 0, 0);
    //        for (int s = 0; s < samples_per_pixel; ++s) {
    //            auto u = (i + random_double()) / (image_width - 1);
    //            auto v = (j + random_double()) / (image_height - 1);
    //            ray r = cam.get_ray(u, v);
    //            pixel_color += ray_color(r, world, max_depth);
    //        }
    //        pixelList.push_back(write_color(std::cout, pixel_color, samples_per_pixel));
    //    }
    //}

    /****** io ******/

    // ��һ���ļ���д������
    std::ofstream outfile("image.ppm", std::ios::out);

    // ����ļ��Ƿ�ɹ���
    if (!outfile.is_open()) {
        std::cerr << "Error: Unable to open the file." << "\n";
        return 1;
    }
    outfile << "P3\n" << image_width << ' ' << image_height << "\n255\n";
    
    // ����std::vector������ÿ��Person�ṹ������д���ļ�
    for (const Pixel& p : pixelList) {
        outfile << p.r << ' ' << p.g << ' ' << p.b << "\n";
    }

    // �ر��ļ������
    outfile.close();


    // ��¼����ʱ��
    auto end_time = std::chrono::high_resolution_clock::now();

    // ����ִ��ʱ��
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();

    // ��ӡִ��ʱ��
    std::cout << "Program execution time: " << duration << " milliseconds" << std::endl;


    std::cerr << "\nDone.\n";
}
