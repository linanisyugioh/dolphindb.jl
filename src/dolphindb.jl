module dolphindb
using Pkg.Artifacts

# 使用 Artifacts 动态加载库文件
function __init__()
    # 确保 artifact 可用
    lib_dir = artifact"dolphindb_lib"
    # 根据平台设置库路径
    global dlfile
    if Sys.iswindows()
        dlfile = joinpath(lib_dir, "libmy_dolphindb_api.dll")
    elseif Sys.islinux()
        dlfile = joinpath(lib_dir, "libmy_dolphindb_api.so")
    end
    # 验证库文件是否存在
    if !isfile(dlfile)
        @error "dolphindb library files not found. Please make sure the package is installed correctly."
    end
    global lib = Libc.Libdl.dlopen(dlfile)
end

function close_dll()
    global lib
    Libc.Libdl.dlclose(lib)
    lib = nothing
end

function reload_dll()
    close_dll()
    global dlfile
    global lib = Libc.Libdl.dlopen(dlfile)
end

function ddb_connect(host::String, port::Integer, user::String, pswd::String)::Int64
    sym = Libc.Libdl.dlsym(lib, :my_dolphindb_connect)
    conn_id = ccall(sym, Int64, (Ptr{UInt8}, Int32, Ptr{UInt8}, Ptr{UInt8}), host, Int32(port), user, pswd)
    return conn_id
end

function ddb_connect()::Int64
    global host, port, usr, psw, conn_id
    conn_id = ddb_connect(host, port, usr, psw)
end
export ddb_connect

function ddb_close(conn_id::Int64)::Int64
    sym = Libc.Libdl.dlsym(lib, :my_dolphindb_close)
    val = ccall(sym, Int64, (Int64, ), conn_id)
    return val
end

function ddb_close()::Int64
    global conn_id
    ddb_close(conn_id)
end
export ddb_close

function ddb_database(conn_id::Int64, db_path::String)::Int64
    create_flag = 0
    create_mode = Int32(0)
    create_params = ""
    sym = Libc.Libdl.dlsym(lib, :my_dolphindb_database)
    db_id = ccall(sym, Int64, (Int64, Ptr{Cuchar}, Bool, Int32, Ptr{Cuchar}), conn_id, db_path, create_flag, create_mode, create_params)
    return db_id
end
export ddb_database

function ddb_table(db_id::Int64, table_name::String)
    craete_flag = 0
    create_mode = 0
    create_params=""
    sym = Libc.Libdl.dlsym(lib, :my_dolphindb_table)
    table_id = ccall(sym, Int64, (Int64, Ptr{Cuchar}, Bool, Int32, Ptr{Cuchar}), db_id, table_name, craete_flag, create_mode, create_params)
    return table_id
end

function ddb_stream_table(conn_id::Int64, table_name::String)
    sym = Libc.Libdl.dlsym(lib, :my_dolphindb_stream_table)
    table_id = ccall(sym, Int64, (Int64, Ptr{Cuchar}), conn_id, table_name)
    return table_id
end

function ddb_add_column(table_id::Int64, col_name::String, col_data::Vector)
    typedict = Dict{DataType, Int}()
    typedict[Vector{Bool}] = 1
    typedict[Vector{Char}] = 2
    typedict[Vector{Int16}] = 3
    typedict[Vector{Int32}] = 4
    typedict[Vector{Int64}] = 5
    typedict[Vector{Float32}] = 15
    typedict[Vector{Float64}] = 16
    typedict[Vector{String}] = 18
    sym = Libc.Libdl.dlsym(lib, :my_dolphindb_add_colum)
    if typeof(col_data) in keys(typedict)
        data_type = typedict[typeof(col_data)]
    end
    if data_type == 18
        val = ccall(sym, Int64, (Int64, Ptr{UInt8}, Ptr{Ptr{UInt8}}, Int32, Int32), table_id, col_name, col_data, length(col_data), data_type)
    else
        val = ccall(sym, Int64, (Int64, Ptr{UInt8}, Ptr{UInt8}, Int32, Int32), table_id, col_name, col_data, length(col_data), data_type) 
    end
    return val
end

function ddb_add_column(col_name::String, col_data::Vector)
    global table_id
    ddb_add_column(table_id, col_name, col_data)
end

function ddb_add_column(table_id::Int64, col_name::String, col_data::Vector{Int64}, format_str::String)
    sym = Libc.Libdl.dlsym(lib, :my_dolphindb_add_datetime_colum)
    val = ccall(sym, Int64, (Int64, Ptr{UInt8}, Ptr{UInt8}, Int32, Ptr{UInt8}), table_id, col_name, col_data, length(col_data), format_str)
    return val
end

function ddb_add_column(col_name::String, col_data::Vector{Int64}, format_str::String)
    global table_id
    ddb_add_column(table_id, col_name, col_data, format_str)
end
export ddb_add_column

function ddb_upload_table(table_id::Int64, colum_handers::Vector{String})
    sym = Libc.Libdl.dlsym(lib, :my_dolphindb_upload_table)
    val = ccall(sym, Int64, (Int64, Ptr{Ptr{UInt8}}, Int32), table_id, colum_handers, length(colum_handers))
    return val
end

function ddb_upload_table(colum_handers::Vector{String})
    global table_id
    ddb_upload_table(table_id, colum_handers)
end
export ddb_upload_table

function ddb_close_table(table_id::Int64)
    sym = Libc.Libdl.dlsym(lib, :clear_table_var)
    ccall(sym, Cvoid, (Int64, ), table_id)
end

function ddb_close_db(db_id::Int64)
    sym = Libc.Libdl.dlsym(lib, :clear_db_var)
    ccall(sym, Cvoid, (Int64, ), db_id)
end

function init()
    global dlfile
    global lib = Libc.Libdl.dlopen(dlfile)
    ddb_reset()
end

function init(host0::String,port0::Int,usr0::String,psw0::String,table_name0::String,
              db_path0::String)
    global host = host0
    global port = port0
    global usr = usr0
    global psw = psw0
    global table_name = table_name0
    global db_path = db_path0
# 1表示分区表； 2表示流表；    
    global table_type = 1
    ddb_close_all()
    global dlfile
    global lib = Libc.Libdl.dlopen(dlfile)
    ddb_reset()
end

function init(host0::String,port0::Int,usr0::String,psw0::String,table_name0::String)
    global host = host0
    global port = port0
    global usr = usr0
    global psw = psw0
    global table_name = table_name0
# 1表示分区表； 2表示流表；    
    global table_type = 2    
    ddb_close_all()
    global dlfile
    global lib = Libc.Libdl.dlopen(dlfile)
    ddb_reset()
end

function ddb_reset()
    global table_type
    ddb_close_all()
    global host, port, usr, psw, db_path, table_name
    global conn_id = ddb_connect(host, port, usr, psw)
    if table_type == 1 
        global db_id = ddb_database(conn_id, db_path)
        global table_id = ddb_table(db_id, table_name)
    elseif table_type == 2
        global table_id = ddb_stream_table(conn_id, table_name)
    end
end
export ddb_reset

function ddb_reset_table()
    global table_id, table_type
    ddb_close_table(table_id)
    if table_type == 1
        global db_id
        global table_id = ddb_table(db_id, table_name)
    elseif table_type == 2
        global conn_id
        global table_id = ddb_stream_table(conn_id, table_name)
    end
end
export ddb_reset_table

function ddb_close_all()
    global table_id, db_id, conn_id
    if @isdefined table_id
        ddb_close_table(table_id)
    end
    if @isdefined db_id
        ddb_close_db(db_id)
    end
    if @isdefined conn_id
        ddb_close(conn_id)
    end
end
export ddb_close_all

end

