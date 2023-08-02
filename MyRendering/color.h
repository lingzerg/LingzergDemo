#pragma once

#ifndef COLOR_H
#define COLOR_H

#include "vec3.h"

#include <iostream>

Pixel write_color(std::ostream& out, color pixel_color, int samples_per_pixel) {
    Pixel p;
    
    auto r = pixel_color.x();
    auto g = pixel_color.y();
    auto b = pixel_color.z();

    // Divide the color by the number of samples and gamma-correct for gamma=2.0.
    auto scale = 1.0 / samples_per_pixel;
    r = sqrt(scale * r);
    g = sqrt(scale * g);
    b = sqrt(scale * b);

    p.r = static_cast<int>(256 * clamp(r, 0.0, 0.999));
    p.g = static_cast<int>(256 * clamp(g, 0.0, 0.999));
    p.b = static_cast<int>(256 * clamp(b, 0.0, 0.999));

    return p;
    // Write the translated [0,255] value of each color component.
    /*out << static_cast<int>(256 * clamp(r, 0.0, 0.999)) << ' '
        << static_cast<int>(256 * clamp(g, 0.0, 0.999)) << ' '
        << static_cast<int>(256 * clamp(b, 0.0, 0.999)) << '\n';*/
}

#endif