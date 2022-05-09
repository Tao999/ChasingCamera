extends Spatial
# Declare member variables here. Examples:
export (float) var threshold_speed = 2.5
export (float) var auto_cam_speed = 6
export (float) var auto_release_return = 1
export (float) var controller_smooth_speed = 4

var direction = Vector3.FORWARD
var wanted_dir : Vector3 = Vector3(0, 0, 0)
var pitch : float = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#on prend la velocité absolue
	var currunt_velocity : Vector3 = get_parent().get_linear_velocity()
	var par_rot : Vector3 = get_parent().get_global_transform().basis.z
	
	var plan_currunt_velocity : Vector3 = currunt_velocity
	
	plan_currunt_velocity.y = 0
	
	# get controller wanted direction
	wanted_dir.x = Input.get_axis("ct_look_right", "ct_look_left")
	wanted_dir.z = Input.get_axis("ct_look_back", "ct_look_front")
	
	if wanted_dir.length() != 0:
		#manual control
		var rot : Vector2 = Vector2(par_rot.x, par_rot.z).normalized()
		
		#calculate relative front of between the car and wanted dir
		var wanted2d : Vector2 = Vector2(wanted_dir.x, wanted_dir.z)
		var rel_front2d : Vector2 = rot.rotated(wanted2d.angle())
		#change to Vector3
		var relative_front : Vector3 = Vector3(-rel_front2d.y, 0, rel_front2d.x)
		
		wanted_dir = wanted_dir.normalized()
		
		#go behind vehicle during oposite angle movements and transform.basis.y.angle_to(Vector3.DOWN) > 1.5:
		if wanted_dir.angle_to(transform.basis.z) > 2.5:
			var phi : float = -PI/2 if wanted_dir.signed_angle_to(par_rot, Vector3.DOWN) > 0 else PI/2
			relative_front = relative_front.rotated(Vector3.UP, phi)
		
		direction = lerp(direction.normalized(), relative_front, controller_smooth_speed * delta * wanted2d.length())
	
	elif plan_currunt_velocity.length() > threshold_speed:
		#auto control
		var flaten : float = 0.5
		var shift : float = 3
		#use of simoide function to have a smooth movement at low speed
		var sigmoide : float = 1/(1+exp(-flaten*plan_currunt_velocity.length() + shift))
		direction = lerp(direction.normalized(), -plan_currunt_velocity.normalized(), auto_cam_speed * delta * sigmoide)
		
	
	else:
		#auto released
		var relative_forward : Vector3 = par_rot
		relative_forward.y = 0
		relative_forward *= -1
		direction = lerp(direction.normalized(), relative_forward, auto_release_return * delta)
	
	#apply rotation to global transform
	global_transform.basis = get_rotation_from_dir(direction)
	
	
	#apply pitch in function of Y velocity
	var flaten : float = 0.2
	var sigmoide : float = 1/(1+exp(-flaten*currunt_velocity.y))*2-1
	pitch = lerp(pitch, -sigmoide * PI/8, auto_cam_speed*delta)
	
	#this one is a faster way, but ignore Y velocity (less fancy)
	#pitch = lerp(pitch, -par_rot.y, auto_cam_speed*delta)
	
	#apply pitch to local rotation
	rotate_object_local(Vector3.RIGHT, pitch)


func get_rotation_from_dir(look_dir : Vector3) -> Basis:
	look_dir = look_dir.normalized() #like Vector3.BACK
	var x_axis = look_dir.cross(Vector3.UP).normalized() #like Vector3.RIGHT
	return Basis(x_axis, Vector3.UP, -look_dir)
