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


  //All Tenants
  getAllTenants() {
    return this._supabase.rpc("get_all_tenants");
  }

  //User Tenants
  getTenants() {
    return this._supabase.rpc("get_tenants");
  }

  //Get Users
  getUserSession() {
    return this._supabase.auth.getUser()
  }

  getTenantMembers(id: any) {
    return this._supabase.rpc("get_tenant_members", { tenant_id: id });
  }
}