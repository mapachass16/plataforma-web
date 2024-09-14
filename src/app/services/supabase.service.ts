import { inject, Injectable, NgZone } from '@angular/core';
import { environment } from '../../environments/environment';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

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

  getDeviceUsers() {
    return this._supabase.from('device_users').select('*');
  }
}
