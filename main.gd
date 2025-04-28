extends Node3D

var object_count := 1000
const SAMPLE_FRAMES := 600
var frame_times: Array = []
var last_physics_time_usec := 0
var num_threads := 1

func _ready():
	var args = OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "--object-count" and i + 1 < args.size():
			object_count = int(args[i + 1])
		if args[i] == "--num-threads" and i + 1 < args.size():
			num_threads = int(args[i + 1])
			
	# Debug print
	print("Running with ", num_threads, 
		  " threads and ", object_count, " objects")
	if num_threads > 1:
		ProjectSettings.set_setting("physics/3d/run_on_separate_thread", true)
	else:
		ProjectSettings.set_setting("physics/3d/run_on_separate_thread", false)

	print("--- STRONG SCALING BENCHMARK START ---")
	spawn_objects(object_count)
	last_physics_time_usec = Time.get_ticks_usec()

func spawn_objects(count):
	var packed = preload("res://physics_object.tscn")
	var radius = 20.0
	for i in range(count):
		var instance = packed.instantiate()
		instance.position = Vector3(
			randf_range(-radius, radius),
			randf_range(10.0, radius + 10.0),  # Start higher
			randf_range(-radius, radius)
		)
		instance.linear_velocity = Vector3(
			randf_range(-10, 10),
			randf_range(-10, 10),
			randf_range(-10, 10)
		)
		add_child(instance)

func _physics_process(_delta):
	var now = Time.get_ticks_usec()
	var elapsed = now - last_physics_time_usec
	frame_times.append(elapsed / 1000.0)
	last_physics_time_usec = now

	if frame_times.size() >= SAMPLE_FRAMES:
		var avg = frame_times.reduce(func(a, b): return a + b) / frame_times.size()
		print("RESULT: object_count=", object_count, " avg_frame_time=", avg)
		
		var args = OS.get_cmdline_args()
		if "--quit-after-benchmark" in args:
			get_tree().quit()
