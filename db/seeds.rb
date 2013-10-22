admin = User.new
admin.email = "admin@coursepacker.org"
admin.password = "TEMP123"
admin.add_role :admin
admin.registered = true
admin.save