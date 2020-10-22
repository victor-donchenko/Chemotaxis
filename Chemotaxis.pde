class Vector2D {
  double x;
  double y;
  
  Vector2D(double i_x, double i_y) {
    x = i_x;
    y = i_y;
  }
  
  Vector2D(Vector2D other) {
    this(other.x, other.y);
  }
  
  void assign(Vector2D other) {
    x = other.x;
    y = other.y;
  }
  
  Vector2D multiply(double other) {
    return new Vector2D(x * other, y * other);
  }
  
  Vector2D divide(double other) {
    return new Vector2D(x / other, y / other);
  }
  
  Vector2D plus(Vector2D other) {
    return new Vector2D(x + other.x, y + other.y);
  }
  
  Vector2D minus(Vector2D other) {
    return new Vector2D(x - other.x, y - other.y);
  }
  
  double magnitude_sq() {
    return x * x + y * y;
  }
  
  double magnitude() {
    return Math.sqrt(magnitude_sq());
  }
  
  Vector2D normalize() {
    double magn = magnitude();
    if (magn == 0) {
      return new Vector2D(0, 0);
    }
    else {
      return this.divide(magn);
    }
  }
  
  void update_by(Vector2D other) {
    x += other.x;
    y += other.y;
  }
}

class Bird {
  final double mass = 1.0;
  final double force_factor = 20;
  final double main_body_radius = 10;
  final double head_side_length = 5;
  
  Flock flock;
  Vector2D location;
  Vector2D velocity;
  
  Bird(Flock i_flock, Vector2D i_location, Vector2D i_velocity) {
    flock = i_flock;
    location = i_location;
    velocity = i_velocity;
  }
  
  void update(double time_delta) {
    Vector2D towards_center_force
      = flock.bird_set.get_average_location().minus(location).normalize().multiply(10);
    Vector2D vec_to_goal = flock.goal.minus(location);
    Vector2D towards_goal_force
      = vec_to_goal.divide(20);
    Vector2D next_vec_to_goal = flock.goal.minus(location.plus(velocity));
    if (next_vec_to_goal.magnitude() > vec_to_goal.magnitude()) {
      towards_goal_force = towards_goal_force.multiply(2);
    }
    Bird[] adjacent_birds = flock.bird_set.get_closest_birds(location);
    Vector2D repulsion_force = new Vector2D(0, 0);
    for (int i = 0; i < adjacent_birds.length; ++i) {
      Bird adjacent_bird = adjacent_birds[i];
      repulsion_force.update_by(location.minus(adjacent_bird.location).normalize());
    }
    repulsion_force = repulsion_force.normalize().multiply(6);
    
    Vector2D total_force
      = towards_center_force.multiply(1.0/6)
        .plus(towards_goal_force.multiply(5.0/12))
        .plus(repulsion_force.multiply(5.0/12));
    total_force = total_force.multiply(force_factor * time_delta / mass);
    
    velocity.update_by(total_force);
  }
  
  void show() {
    fill(color(0x00, 0x00, 0xff));
    stroke(color(0xff, 0xff, 0xff));
    strokeWeight(1);
    ellipseMode(RADIUS);
    ellipse(
      (float)location.x,
      (float)location.y,
      (float)main_body_radius,
      (float)main_body_radius
    );
    
    Vector2D normalized_velocity = velocity.normalize();
    Vector2D head_center = location.plus(normalized_velocity.multiply(main_body_radius));
    Vector2D head_offset_y = normalized_velocity.multiply(head_side_length / 2);
    Vector2D head_offset_x
      = new Vector2D(-normalized_velocity.y, normalized_velocity.x).multiply(head_side_length / 2);
    Vector2D head_corner1 = head_center.plus(head_offset_x).plus(head_offset_y);
    Vector2D head_corner2 = head_center.minus(head_offset_x).plus(head_offset_y);
    Vector2D head_corner3 = head_center.minus(head_offset_x).minus(head_offset_y);
    Vector2D head_corner4 = head_center.plus(head_offset_x).minus(head_offset_y); 
    quad(
      (float)head_corner1.x,
      (float)head_corner1.y,
      (float)head_corner2.x,
      (float)head_corner2.y,
      (float)head_corner3.x,
      (float)head_corner3.y,
      (float)head_corner4.x,
      (float)head_corner4.y
    );
  }
}

class BirdSet {
  ArrayList<Bird> birds;
  Vector2D cached_average_location;
  
  BirdSet() {
    birds = new ArrayList<Bird>();
  }
  
  void add(Bird bird) {
    birds.add(bird);
  }
  
  void reindex() {
    Vector2D sum_of_locations = new Vector2D(0, 0);
    for (Bird bird : birds) {
      sum_of_locations.update_by(bird.location);
    }
    cached_average_location = sum_of_locations.divide(birds.size());
  }
  
  Vector2D get_average_location() {
    return cached_average_location;
  }
  
  Bird[] get_closest_birds(Vector2D location) {
    double[] distances = { 0, 0, 0 };
    int[] indices = { -1, -1, -1 };
    for (int i = 0; i < birds.size(); ++i) {
      Bird bird = birds.get(i);
      double distance = bird.location.minus(location).magnitude();
      if (indices[0] == -1 || distance < distances[0]) {
        distances[2] = distances[1];
        indices[2] = indices[1];
        distances[1] = distances[0];
        indices[1] = indices[0];
        distances[0] = distance;
        indices[0] = i;
      }
      else if (indices[1] == -1 || distance < distances[1]) {
        distances[2] = distances[1];
        indices[2] = indices[1];
        distances[1] = distance;
        indices[1] = i;
      }
      else if (indices[2] == -1 || distance < distances[2]) {
        distances[2] = distance;
        indices[2] = i;
      }
    }
    
    if (indices[0] == -1) {
      Bird[] out = {};
      return out;
    }
    else if (indices[1] == -1) {
      Bird[] out = {
        birds.get(indices[0])
      };
      return out;
    }
    else if (indices[2] == -1) {
      Bird[] out = {
        birds.get(indices[0]),
        birds.get(indices[1])
      };
      return out;
    }
    else {
      Bird[] out = {
        birds.get(indices[0]),
        birds.get(indices[1]),
        birds.get(indices[2])
      };
      return out;
    }
  }
}

class Flock {
  ArrayList<Bird> birds;
  BirdSet bird_set;
  Vector2D goal;
  
  Flock() {
    birds = new ArrayList<Bird>();
    bird_set = new BirdSet();
    goal = new Vector2D(0, 0);
  }
  
  void set_goal(Vector2D new_goal) {
    goal.assign(new_goal);
  }
  
  void add_bird(Vector2D location) {
    Bird new_bird = new Bird(
      this,
      new Vector2D(location),
      new Vector2D(0, 0)
    ); 
    birds.add(new_bird);
    bird_set.add(new_bird);
  }
  
  void show() {
    for (Bird bird : birds) {
      bird.show();
    }
  }
  
  void update(double time_delta) {
    for (Bird bird : birds) {
      bird.location.update_by(bird.velocity.multiply(time_delta));
    }
    bird_set.reindex();
    for (Bird bird : birds) {
      bird.update(time_delta);
    }
  }
}

Flock flock;

void setup() {
  size(300, 300);
  flock = new Flock();
}

void draw() {
  background(color(0xff, 0xff, 0xff));
  translate(150, 150);
  flock.show();
  flock.set_goal(new Vector2D(mouseX - 150, mouseY - 150));
  flock.update(1.0 / frameRate);
}

void mousePressed() {
  flock.add_bird(new Vector2D(0, 0));
}
