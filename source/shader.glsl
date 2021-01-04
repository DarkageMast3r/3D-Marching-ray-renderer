uniform mat3x3 cframe;
uniform vec3 position;
uniform float time;
uniform vec4 lights[2];
uniform bool castShadows;

struct sphere{
    vec3 position;
    float radius;
    vec4 color;
    bool castShadow;
    float reflectancy;
};

struct inverseSphere{
    vec3 position;
    float radius;
    vec4 color;
    bool castShadow;
    float reflectancy;
};

struct plane{
    vec3 position;
    vec3 up;
    vec4 color;
    bool castShadow;
    float reflectancy;
};

struct cube{
    vec3 position;
    vec3 size;
    vec4 color;
    bool castShadow;
    float reflectancy;
};

struct hitData{
    vec3 position;
    vec3 normal;
    vec4 color;
    float travelledDistance;
    int steps;
    bool hasHit;
    float reflectancy;
};

sphere spheres[29];
inverseSphere inverseSpheres[2];
plane planes[1];
cube cubes[9];


bool isInRadius(vec3 p, float radius) {
    float disSqrd = p.x * p.x + p.y * p.y + p.z * p.z;
    return disSqrd < radius * radius;
}

float inverseLerp(float a, float b, float i) {
    return (i-a) / (b - a);
}

vec3 getReflectedDirection(vec3 direction, vec3 normal) {
    float d = dot(direction, normal);
    return normalize(direction - d * normal);
}


float getDistance(sphere object, vec3 position) {
    return distance(position, object.position) - object.radius;
}
vec3 getNormal(sphere object, vec3 position) {
    return normalize(position - object.position);
}

float getDistance(inverseSphere object, vec3 position) {
    return abs(distance(position, object.position) - object.radius);
}
vec3 getNormal(inverseSphere object, vec3 position) {
    return -normalize(position - object.position);
}

float getDistance(plane object, vec3 position) {
    return dot(object.up, position - object.position);
}
vec3 getNormal(plane object, vec3 position) {
    return object.up;
}

float getDistance(cube object, vec3 position) {
    vec3 dif = position - object.position;
    vec3 closest = vec3(
        clamp(dif.x, -object.size.x/2, object.size.x/2),
        clamp(dif.y, -object.size.y/2, object.size.y/2),
        clamp(dif.z, -object.size.z/2, object.size.z/2)
    );
    return distance(closest, dif);
}
vec3 getNormal(cube object, vec3 position) {
    vec3 dif = position - object.position;
    vec3 closest = vec3(
        clamp(dif.x, -object.size.x/2, object.size.x/2),
        clamp(dif.y, -object.size.y/2, object.size.y/2),
        clamp(dif.z, -object.size.z/2, object.size.z/2)
    );
    return normalize(dif-closest);
}



float lightValue(vec3 position, vec4 light) {
    vec3 curPos = position;
    vec3 direction = normalize(light.xyz - curPos);
    float travelledDistance = 0;
    float wantedDistance = distance(light.xyz, curPos);
    int steps = 0;

    while (travelledDistance < wantedDistance - 0.01) {
        steps++;
        float maxDis = wantedDistance - travelledDistance;

        if (castShadows) {
            int i;
            for (i = 0; i < spheres.length(); i++) {
                if (spheres[i].castShadow) {
                    maxDis = min(maxDis, getDistance(spheres[i], curPos));
                }
            }
            for (i = 0; i < inverseSpheres.length(); i++) {
                if (inverseSpheres[i].castShadow) {
                    maxDis = min(maxDis, getDistance(inverseSpheres[i], curPos));
                }
            }
            for (i = 0; i < planes.length(); i++) {
                if (planes[i].castShadow) {
                    maxDis = min(maxDis, getDistance(planes[i], curPos));
                }
            }
            for (i = 0; i < cubes.length(); i++) {
                if (cubes[i].castShadow) {
                    maxDis = min(maxDis, getDistance(cubes[i], curPos));
                }
            }
        }

        travelledDistance += maxDis;
        curPos += direction * maxDis;


        if (maxDis < 0.01 && (!isInRadius(position - curPos, 0.1) || steps > 5)) {
            return 0;
        }
    }

    return light.w / wantedDistance;
}

float lightValue(vec3 position) {
    int i;
    float lightness = 0;
    for (i = 0; i < lights.length(); i++) {
        lightness += lightValue(position, lights[i]);
    }
    return lightness;
}

hitData marchRay(vec3 position, vec3 direction) {
    direction = normalize(direction);
    vec4 color;
    vec3 currentPosition = position;
    vec3 actDir = direction;
    vec3 normal;
    int steps;
    int maxSteps = 256;

    float maxDis;
    float travelledDistance;
    float reflectancy = 0;

    for (steps = 1; steps < maxSteps; steps++) {
        maxDis = 15.0;

        int i;
        for (i = 0; i < spheres.length(); i++) {
            float dis = getDistance(spheres[i], currentPosition);
            if (dis < maxDis) {
                maxDis = dis;
                color = spheres[i].color;
                normal = getNormal(spheres[i], currentPosition);
                reflectancy = spheres[i].reflectancy;
            }
        }
        
        for (i = 0; i < inverseSpheres.length(); i++) {
            float dis = getDistance(inverseSpheres[i], currentPosition);
            if (dis < maxDis) {
                maxDis = dis;
                color = inverseSpheres[i].color;
                normal = getNormal(inverseSpheres[i], currentPosition);
                reflectancy = inverseSpheres[i].reflectancy;
            }
        }
        
        for (i = 0; i < planes.length(); i++) {
            float dis = getDistance(planes[i], currentPosition);
            if (dis < maxDis) {
                maxDis = dis;
                color = planes[i].color;
                normal = getNormal(planes[i], currentPosition);
                reflectancy = planes[i].reflectancy;
            }
        }
        
        for (i = 0; i < cubes.length(); i++) {
            float dis = getDistance(cubes[i], currentPosition);
            if (dis < maxDis) {
                maxDis = dis;
                color = cubes[i].color;
                normal = getNormal(cubes[i], currentPosition);
                reflectancy = cubes[i].reflectancy;
            }
        }

        vec3 closestPortal = dot(vec3(0, 75, 0) - currentPosition, actDir) * actDir + currentPosition;
        vec3 portalDir = (currentPosition - closestPortal);
        bool inRange = isInRadius(closestPortal - vec3(0, 75, 0), 15);

        travelledDistance += maxDis;
        currentPosition = currentPosition + actDir * maxDis;

        // bending light rays
        bool inFront = dot(currentPosition, portalDir) < 0;
        if (inRange && !inFront) {
            currentPosition = vec3(500, 75, 0) + (currentPosition - vec3(0, 75, 0)) * 1;
        }

        if (maxDis < 0.01 && (!isInRadius(position - currentPosition, 0.01) || steps > 1)) {
            return hitData(
                currentPosition,
                normal,
                color * lightValue(currentPosition),
                travelledDistance,
                steps,
                true,
                reflectancy
            );
        }
    }

    if (maxDis < 0.01) {
        return hitData(
            currentPosition,
            normal,
            color * lightValue(currentPosition),
            travelledDistance,
            steps,
            true,
            reflectancy
        );
    } else {
        return hitData(
            currentPosition,
            normal,
            vec4(0.5, 0.5, 1, 1) * lightValue(currentPosition),
            travelledDistance,
            steps,
            false,
            reflectancy
        );
    }
}


hitData getHitData(vec3 position, vec3 direction, float lightStrength) {
    vec4 finalColor = vec4(0,0,0,1);

    vec3 curPos = position;
    vec3 curDir = direction;
    vec3 firstNormal;
    float travelledDistance = 0;
    int curStep;
    int totalSteps;
    bool hasHit = false;
    while (lightStrength > 0) {
        hitData rayData = marchRay(curPos, curDir);
        finalColor = finalColor + rayData.color * lightStrength;
        travelledDistance += rayData.travelledDistance;
        totalSteps += rayData.steps;
        lightStrength *= rayData.reflectancy;
        lightStrength -= 0.1;


        curDir = getReflectedDirection(curDir, rayData.normal);
        curPos = rayData.position + curDir * 0.5;

        if (rayData.hasHit) {
            hasHit = true;
        }

        if (curStep == 1) {
            firstNormal = rayData.normal;
        }
    }

    finalColor.a = 1;

    return hitData(
        curPos,
        firstNormal,
        finalColor,
        travelledDistance,
        totalSteps,
        hasHit,
        0
    );
}

vec4 effect(vec4 color, Image texture, vec2 texCoords, vec2 screenCoords) {
    // Initializing objects
    spheres[0] = sphere(
        vec3(0, -300, 0),
        3,
        vec4(1, 0, 0, 1),
        false,
        0
    );
    spheres[1] = sphere(
        vec3(cos(time) * 5, 300, sin(time) * 5),
        3,
        vec4(0, 1, 1, 1),
        false,
        0
    );
    spheres[2] = sphere(
        vec3(cos(time) * 100, 25, sin(time) * 100),
        5,
        vec4(0, 0, 1, 1),
        false,
        0
    );
    spheres[3] = sphere(
        vec3(cos(time * 2) * 50, 70.7, sin(time * 2) * 50),
        5,
        vec4(1, 1, 0, 1),
        false,
        1
    );
    spheres[4] = sphere(
        vec3(0, 25, 0),
        25,
        vec4(1, 0, 0, 1),
        true,
        1
    );
    float r;
    int i = 4;
    for (r = 0.0; r < 360.0; r = r + 15.0) {
        i++;
        spheres[i] = sphere(
            vec3(cos(radians(r)) * 50, ( -cos(time + radians(r))) * 5 + 25, sin(radians(r)) * 50),
            abs(cos(time + radians(r)) * 5),
            vec4(1, 0, 1, 1),
            true,
            1
        );
    }

    planes[0] = plane(
        vec3(0, -12, 0),
        vec3(0, 1, 0),
        vec4(0, 1, 0, 1),
        false,
        1
    );

    inverseSpheres[0] = inverseSphere(
        vec3(0, 0, 0),
        200,
        vec4(0.25, 0.25, 1, 1),
        false,
        0
    );

    inverseSpheres[1] = inverseSphere(
        vec3(500, 0, 0),
        200,
        vec4(0.25, 0.25, 1, 1),
        false,
        0
    );

    int x;
    int y;
    i = 0;
    for (x = -1; x <= 1; x++) {
        for (y = -1; y <= 1; y++) {
            cubes[i] = cube(
                vec3(x * 50 + 500, -12, y * 50),
                vec3(40, 5, 40),
                vec4(0, 1, 1, 1),
                false,
                0
            );
            i++;
        }
    }
    


    hitData data = getHitData(
        position,
        cframe[0] + cframe[1] * (-texCoords.y+0.5) + cframe[2] * (texCoords.x-0.5),
        1
    );
    float ambientOcclusion = float(1) - float(data.steps)/float(256);
    return data.color * ambientOcclusion;
}
