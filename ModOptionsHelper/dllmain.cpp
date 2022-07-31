



#include "pch.h"

#include "reframework/API.hpp"
#include <sol/sol.hpp>

using API = reframework::API;

lua_State* g_lua{};



GUID PointerToGUID(GUID *ptr){
    return *ptr;
}


void on_ref_lua_state_created(lua_State* l) try {

    g_lua = l;
    sol::state_view lua{l};

    lua["PtrToGuidTest"] = [](void* ptr) {

        auto g = PointerToGUID((GUID*)ptr);

        //no idea how to really return a valuetype as a whole thing
        //I think would have to like return the raw data and then convert it on the lua side
        //auto newG = API::get()->tdb()->find_type("System.Guid")->create_instance();
        //*newG->get_field<UINT32>("mData1") = g.Data1;

        //but this hecking works good enough baybeee
        return g.Data1;
    };
}catch (const std::exception& e) {
    OutputDebugStringA(e.what());
    API::get()->log_error("[reframework-d2d] [on_ref_lua_state_created] %s", e.what());
}

void on_ref_lua_state_destroyed(lua_State* l) try {
    g_lua = nullptr;
} catch (const std::exception& e) {
    OutputDebugStringA(e.what());
    API::get()->log_error("[reframework-d2d] [on_ref_lua_state_destroyed] %s", e.what());
}

extern "C" __declspec(dllexport) bool reframework_plugin_initialize(const REFrameworkPluginInitializeParam* param) {

    if (param->renderer_data->renderer_type != REFRAMEWORK_RENDERER_D3D12) {
        return false;
    }

    reframework::API::initialize(param);

    param->functions->on_lua_state_created(on_ref_lua_state_created);
    param->functions->on_lua_state_destroyed(on_ref_lua_state_destroyed);

    return true;
}