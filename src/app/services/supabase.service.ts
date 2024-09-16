import { inject, Injectable, NgZone } from '@angular/core';
import { environment } from '../../environments/environment';
import {
  AuthChangeEvent,
  AuthSession,
  createClient,
  Session,
  SupabaseClient,
  User,
} from '@supabase/supabase-js'

@Injectable({
  providedIn: 'root',
})
export class SupabaseService {
  public _supabase: SupabaseClient;
  private readonly ngZone = inject(NgZone);

  constructor() {
    this._supabase = this.ngZone.runOutsideAngular(() =>
      createClient(environment.supabaseUrl, environment.supabaseKey)
    );
  }

  //Users
  async signIn(email: string, password: string): Promise<{ user: any; error: any }> {
    const { data, error } = await this._supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      return { user: null, error };
    }
    return { user: data.session, error: null };
  }

  //All tenants
  getAllTenants() {
    return this._supabase.rpc("get_all_tenants");
  }

  //User tenants
  getTenants() {
    return this._supabase.rpc("get_tenants");
  }

  //Get users
  getUserSession() {
    return this._supabase.auth.getUser()
  }

  //Get all members of a tenant
  getTenantMembers(id: any) {
    return this._supabase.rpc("get_tenant_members", { tenant_id: id });
  }

  //Get a tenant's monitored people
  getMonitoredPeople(tenant_id: any) {
    return this._supabase
      .from('device_users')
      .select('*')
      .eq('tenant_id', tenant_id);
  }

  //Get a tenant's devices
  getIoTDevicesByTenant(tenant_id: any) {
    return this._supabase
      .from('iot_devices')
      .select('*')
      .eq('tenant_id', tenant_id);
  }


}